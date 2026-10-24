import 'dart:async';

import 'package:clock/clock.dart';

import '../core/alarm_record.dart';
import '../core/constants.dart';
import '../core/events.dart';
import '../core/message_composer.dart';
import '../core/models.dart';
import '../core/monitor.dart';
import '../data/app_logger.dart';
import '../data/pending_alarm_store.dart';
import 'background/background_task_runner.dart';
import 'location/location_provider.dart';
import 'sms/sms_sender.dart';
import 'telegram/telegram_sender.dart';

/// SMS yedeği modu (yalnızca Android).
enum SmsMode {
  off,
  fallback,
  always;

  static SmsMode byName(String? n) => values.firstWhere((v) => v.name == n, orElse: () => SmsMode.fallback);
}

/// Göndericinin her işlemde okuduğu ayarlar.
class DispatchSettings {
  const DispatchSettings({
    required this.personName,
    required this.chatId,
    required this.smsMode,
    required this.smsFallbackSeconds,
  });
  final String personName;
  final String chatId;
  final SmsMode smsMode;
  final int smsFallbackSeconds;
}

/// Gönderim durumu.
sealed class DeliveryState {
  const DeliveryState();
}

class Idle extends DeliveryState {
  const Idle();
}

class Sending extends DeliveryState {
  const Sending();
}

class Delivered extends DeliveryState {
  const Delivered(this.at);
  final DateTime at;
}

class Retrying extends DeliveryState {
  const Retrying(this.attempt);
  final int attempt;
}

class FailedNotified extends DeliveryState {
  const FailedNotified(this.attempt);
  final int attempt;
}

class SmsSent extends DeliveryState {
  const SmsSent(this.at);
  final DateTime at;
}

/// Alarmı Telegram'a (ve Android'de SMS'e) taşır; internet yoksa kuyrukta
/// tutup 30 sn'de bir yeniden dener. Zamanlama [tick] ile yürür.
class AlarmDispatcher implements AlarmSink {
  AlarmDispatcher({
    required DispatchSettings Function() settings,
    required Future<String?> Function() token,
    required Future<List<EmergencyContact>> Function() contacts,
    required TelegramSender telegram,
    required LocationProvider location,
    required SmsSender sms,
    required PendingAlarmStore store,
    required MonitorEvents events,
    BackgroundTaskRunner? backgroundTask,
  })  : _settings = settings,
        _token = token,
        _contacts = contacts,
        _telegram = telegram,
        _location = location,
        _sms = sms,
        _store = store,
        _events = events,
        _bg = backgroundTask ?? NoopBackgroundTaskRunner();

  final DispatchSettings Function() _settings;
  final Future<String?> Function() _token;
  final Future<List<EmergencyContact>> Function() _contacts;
  final TelegramSender _telegram;
  final LocationProvider _location;
  final SmsSender _sms;
  final PendingAlarmStore _store;
  final MonitorEvents _events;
  final BackgroundTaskRunner _bg;

  final StreamController<DeliveryState> _delivery = StreamController<DeliveryState>.broadcast();
  DeliveryState _state = const Idle();

  AlarmRecord? _current;
  Coord? _coord;
  Coord? _lastSentCoord;
  DateTime? _nextAttemptAt;
  DateTime? _nextLocationTry;
  DateTime? _lastLiveEdit;
  bool _busy = false;
  bool _liveBusy = false;
  bool _failNotified = false;
  // ignore: cancel_subscriptions
  StreamSubscription<Coord>? _liveSub;
  int? _bgTask;

  Stream<DeliveryState> get delivery => _delivery.stream;
  DeliveryState get state => _state;
  AlarmRecord? get current => _current;
  Coord? get lastCoord => _coord;

  void _emit(DeliveryState s) {
    _state = s;
    _delivery.add(s);
  }

  Future<void> _save(AlarmRecord r) async {
    try {
      await _store.save(r);
    } on Object catch (e) {
      AppLogger.e('Alarm diske yazılamadı', e);
    }
  }

  // ------------------------------------------------------------ AlarmSink

  @override
  void dispatch(AlarmRecord r) {
    final cur = _current;
    if (cur != null && cur.closedAt == null) {
      AppLogger.w('Açık alarm varken yeni alarm istendi; yok sayıldı');
      return;
    }
    _current = r;
    _coord = null;
    _lastSentCoord = null;
    _lastLiveEdit = null;
    _failNotified = false;
    _nextAttemptAt = null;
    _nextLocationTry = null;
    _emit(const Sending());
    AppLogger.i('Alarm başladı: ${r.reason.type}');
    unawaited(_start(r));
  }

  Future<void> _start(AlarmRecord r) async {
    _bgTask = await _bg.begin();
    await _save(r);
    _startLiveStream();
    final s = _settings();
    if (s.smsMode == SmsMode.always && _sms.available && !r.smsAttempted) {
      unawaited(_sendSms(r));
    }
    // KARAR: Konum en fazla 8 sn beklenir; gelmezse metin konumsuz gider.
    try {
      final c = await _location.current(timeout: K.locationTimeout);
      if (c != null) _coord = c;
    } on Object catch (e) {
      AppLogger.w('Konum alınamadı: $e');
    }
    if (!identical(_current, r)) return;
    await _attempt(r);
  }

  void _startLiveStream() {
    if (_liveSub != null) return;
    try {
      _liveSub = _location.live().listen(
        (c) => _coord = c,
        onError: (Object e) => AppLogger.w('Canlı konum akışı: $e'),
      );
    } on Object catch (e) {
      AppLogger.w('Canlı konum başlatılamadı: $e');
    }
  }

  Future<void> _stopLiveStream() async {
    final s = _liveSub;
    _liveSub = null;
    // Beklenmez: iptal geleceği kök zonda tamamlanır, kapatma mesajını geciktirmemeli.
    unawaited(s?.cancel());
  }

  Future<void> _attempt(AlarmRecord r) async {
    if (_busy || r.delivered) return;
    _busy = true;
    r.attempts++;
    final now = clock.now();
    _nextAttemptAt = now.add(K.retryInterval);
    try {
      final token = await _token() ?? '';
      final s = _settings();
      if (token.isEmpty || s.chatId.isEmpty) {
        throw const TelegramException(401, 'token ya da chat id yok');
      }
      final contacts = await _contacts();
      final delay = clock.now().difference(r.triggeredAt);
      final late = delay >= K.lateNoteThreshold ? delay.inMinutes : 0;
      final text = MessageComposer.alarm(
        record: r,
        name: s.personName,
        location: _coord,
        firstContact: contacts.isEmpty ? null : contacts.first,
        lateMinutes: late,
      );
      await _telegram.sendMessage(token, s.chatId, text);
      r.deliveredAt = clock.now();
      await _save(r);
      _emit(Delivered(r.deliveredAt ?? now));
      AppLogger.i('Alarm teslim edildi (${r.attempts}. deneme)');
      _events.log(
        late > 0 ? EventKind.alarmDeliveredLate : EventKind.alarmSent,
        late > 0 ? 'Alarm $late dk gecikmeyle gruba ulaştı' : 'Alarm gruba ulaştı',
        sentToGroup: true,
      );
      _events.cancel(const AppNotification.ref(AppNotificationKind.failed));
      _events.notify(const AppNotification(
        AppNotificationKind.delivered,
        title: 'Yakınlarına haber verildi',
        body: 'Mesaj gruba ulaştı. Konumun canlı paylaşılıyor.',
      ));
      if (r.closedAt != null) {
        // Kapatma, mesaj yoldayken geldi: grup alarmı gördüğü için kapatmayı da görmeli.
        await _sendClose(r);
        return;
      }
      if (_coord != null) await _sendLive(r);
    } on TelegramException catch (e) {
      AppLogger.w('Alarm gönderilemedi (${r.attempts}. deneme): ${e.code} ${e.description}');
      final ra = e.retryAfter;
      if (ra != null) _nextAttemptAt = clock.now().add(Duration(seconds: ra));
      if (!_failNotified) _emit(Retrying(r.attempts));
      await _save(r);
    } on Object catch (e) {
      AppLogger.e('Alarm gönderiminde beklenmeyen hata', e);
      if (!_failNotified) _emit(Retrying(r.attempts));
      await _save(r);
    } finally {
      _busy = false;
      if (r.delivered && r.liveMessageId != null) await _endBg();
    }
  }

  Future<void> _sendLive(AlarmRecord r) async {
    final c = _coord;
    if (c == null || r.liveMessageId != null || _liveBusy) return;
    _liveBusy = true;
    try {
      final token = await _token() ?? '';
      final s = _settings();
      final id = await _telegram.sendLiveLocation(token, s.chatId, c, livePeriod: K.livePeriodSeconds);
      r.liveMessageId = id;
      r.liveUntil = clock.now().add(const Duration(seconds: K.livePeriodSeconds));
      _lastSentCoord = c;
      _lastLiveEdit = clock.now();
      await _save(r);
      await _endBg();
    } on Object catch (e) {
      AppLogger.w('Canlı konum gönderilemedi: $e');
      _nextLocationTry = clock.now().add(K.retryInterval);
    } finally {
      _liveBusy = false;
    }
  }

  Future<void> _sendSms(AlarmRecord r) async {
    if (r.smsAttempted) return;
    r.smsAttempted = true;
    await _save(r);
    final contacts = await _contacts();
    final phones = contacts.map((c) => c.phone).where((p) => p.trim().isNotEmpty).toList();
    if (phones.isEmpty) {
      AppLogger.w('SMS yedeği: kişi yok');
      return;
    }
    final text = MessageComposer.sms(record: r, name: _settings().personName, location: _coord);
    final ok = await _sms.send(phones, text);
    r.smsSent = ok;
    await _save(r);
    if (ok) {
      final at = clock.now();
      _emit(SmsSent(at));
      _events.log(EventKind.smsSent, '${phones.length} kişiye SMS gönderildi', sentToGroup: true);
      _events.notify(AppNotification(
        AppNotificationKind.smsSent,
        title: 'SMS gönderildi',
        body: '${phones.length} yakınına SMS ile haber verildi.',
      ));
    } else {
      AppLogger.w('SMS yedeği başarısız');
    }
  }

  @override
  void extraSos() {
    final r = _current;
    if (r == null || !r.delivered) return;
    unawaited(() async {
      try {
        final token = await _token() ?? '';
        final s = _settings();
        await _telegram.sendMessage(token, s.chatId, MessageComposer.extraSos(s.personName, clock.now()));
      } on Object catch (e) {
        AppLogger.w('Tekrar SOS mesajı gönderilemedi: $e');
      }
    }());
  }

  @override
  void close({required bool byUser}) {
    final r = _current;
    if (r == null) return;
    r.closedAt = clock.now();
    _current = null;
    _emit(const Idle());
    AppLogger.i('Alarm kapatıldı (kullanıcı: $byUser)');
    unawaited(() async {
      await _stopLiveStream();
      _events.cancel(const AppNotification.ref(AppNotificationKind.failed));
      // KARAR: Hiç teslim edilmemiş alarm kapatılırsa gruba hiçbir şey gitmez.
      if (r.delivered && !_busy) await _sendClose(r);
      if (r.smsSent) {
        final phones = (await _contacts()).map((c) => c.phone).toList();
        await _sms.send(phones, MessageComposer.smsClosed(_settings().personName));
      }
      try {
        await _store.clear();
      } on Object catch (e) {
        AppLogger.e('Bekleyen alarm silinemedi', e);
      }
      await _endBg();
    }());
  }

  Future<void> _sendClose(AlarmRecord r) async {
    final token = await _token() ?? '';
    final s = _settings();
    final closedAt = r.closedAt ?? clock.now();
    for (var i = 0; i < 3; i++) {
      try {
        await _telegram.sendMessage(token, s.chatId, MessageComposer.closed(s.personName, closedAt));
        break;
      } on Object catch (e) {
        AppLogger.w('Kapatma mesajı gönderilemedi: $e');
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }
    final mid = r.liveMessageId;
    if (mid != null) {
      try {
        await _telegram.stopLiveLocation(token, s.chatId, mid);
      } on Object catch (e) {
        AppLogger.w('Canlı konum durdurulamadı: $e');
      }
    }
  }

  Future<void> _endBg() async {
    final id = _bgTask;
    _bgTask = null;
    await _bg.end(id);
  }

  // ------------------------------------------------------------ zaman

  /// Yeniden deneme, SMS yedeği ve canlı konum güncellemesi.
  void tick() {
    final r = _current;
    if (r == null) return;
    final now = clock.now();
    final s = _settings();
    if (!r.delivered) {
      final next = _nextAttemptAt;
      if (next != null && !now.isBefore(next) && !_busy) unawaited(_attempt(r));
      if (!_failNotified && now.difference(r.triggeredAt) >= K.failNotifyAfter) {
        _failNotified = true;
        _emit(FailedNotified(r.attempts));
        _events.notify(const AppNotification(
          AppNotificationKind.failed,
          title: 'Mesaj gönderilemedi',
          body: 'İnternet bekleniyor. Bağlantı gelince yakınlarına hemen gönderilecek.',
        ));
      }
      if (s.smsMode == SmsMode.fallback &&
          _sms.available &&
          !r.smsAttempted &&
          now.difference(r.triggeredAt) >= Duration(seconds: s.smsFallbackSeconds)) {
        unawaited(_sendSms(r));
      }
      return;
    }

    if (r.liveMessageId == null) {
      final nextLoc = _nextLocationTry;
      if (_coord != null) {
        if (nextLoc == null || !now.isBefore(nextLoc)) unawaited(_sendLive(r));
      } else if (nextLoc == null || !now.isBefore(nextLoc)) {
        _nextLocationTry = now.add(K.retryInterval);
        unawaited(() async {
          try {
            final c = await _location.current(timeout: K.locationTimeout);
            if (c != null) _coord = c;
          } on Object catch (e) {
            AppLogger.w('Konum tekrar alınamadı: $e');
          }
        }());
      }
      return;
    }

    final until = r.liveUntil;
    if (until == null || !now.isBefore(until)) {
      if (_liveSub != null) unawaited(_stopLiveStream());
      return;
    }
    final last = _lastLiveEdit;
    final c = _coord;
    if (c != null &&
        !identical(c, _lastSentCoord) &&
        (last == null || now.difference(last) >= K.liveEditInterval)) {
      _lastLiveEdit = now;
      _lastSentCoord = c;
      final mid = r.liveMessageId;
      if (mid == null) return;
      unawaited(() async {
        try {
          final token = await _token() ?? '';
          await _telegram.editLiveLocation(token, s.chatId, mid, c);
        } on Object catch (e) {
          AppLogger.w('Canlı konum güncellenemedi: $e');
        }
      }());
    }
  }

  /// Uygulama/servis yeniden başladığında bekleyen alarmı kaldığı yerden sürdürür.
  Future<AlarmRecord?> resumePendingIfAny() async {
    final r = await _store.load();
    if (r == null) return null;
    if (r.closedAt != null) {
      await _store.clear();
      return null;
    }
    _current = r;
    _failNotified = false;
    final now = clock.now();
    AppLogger.i('Bekleyen alarm diskten yüklendi (teslim: ${r.delivered})');
    if (!r.delivered) {
      _emit(Retrying(r.attempts));
      _nextAttemptAt = now;
      _startLiveStream();
    } else {
      _emit(Delivered(r.deliveredAt ?? now));
      final until = r.liveUntil;
      if (r.liveMessageId == null || (until != null && now.isBefore(until))) _startLiveStream();
    }
    return r;
  }

  Future<void> dispose() async {
    await _stopLiveStream();
    await _delivery.close();
  }
}
