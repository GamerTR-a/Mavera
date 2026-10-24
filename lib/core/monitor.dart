import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';

import 'alarm_reason.dart';
import 'alarm_record.dart';
import 'battery_tracker.dart';
import 'constants.dart';
import 'events.dart';
import 'monitor_phase.dart';
import 'monitor_settings.dart';
import 'ring_protocol.dart';
import 'sleep_schedule.dart';

/// Alarm komutlarını alan taraf (AlarmDispatcher).
abstract class AlarmSink {
  void dispatch(AlarmRecord r);
  void close({required bool byUser});
  void extraSos();
}

/// Monitor'ün dış dünyaya bildirdiği olaylar.
abstract class MonitorEvents {
  void log(EventKind k, String detail, {bool sentToGroup = false});
  void notify(AppNotification n);
  void cancel(AppNotification n);
}

/// Alarm durum makinesi: alarm verip vermeme kararının TEK yeri.
///
/// Saf Dart'tır; zamanı `clock` paketinden alır. Android'de saniyede bir,
/// iOS'ta her satırda [tick] çağrılır.
class Monitor {
  Monitor({
    required MonitorSettings Function() settings,
    required AlarmSink alarms,
    required MonitorEvents events,
    String Function()? idGenerator,
  })  : _settings = settings,
        _alarms = alarms,
        _events = events,
        _newId = idGenerator ?? _defaultId,
        _lastMotionAt = clock.now();

  final MonitorSettings Function() _settings;
  final AlarmSink _alarms;
  final MonitorEvents _events;
  final String Function() _newId;
  final StreamController<MonitorPhase> _changes = StreamController<MonitorPhase>.broadcast();

  MonitorPhase _phase = const Watching();
  DateTime _lastMotionAt;
  int? _ringBattery;
  int? _ringMillivolts;
  final List<int> _recentMoves = <int>[];
  final BatteryTracker battery = BatteryTracker();

  bool _connected = false;
  DateTime? _disconnectedAt;
  bool _disconnectNotified = false;
  DateTime? _lastLineAt;
  int? _lastSeq;
  bool _bat20 = false;
  bool _bat10 = false;
  int? _lastSosSeq;
  DateTime? _lastSosAt;
  int? _lastTrmSeq;
  DateTime? _lastTrmAt;
  DateTime? _lastHeartbeatAt;

  static String _defaultId() =>
      '${clock.now().microsecondsSinceEpoch}-${math.Random().nextInt(1 << 32)}';

  MonitorPhase get phase => _phase;
  DateTime get lastMotionAt => _lastMotionAt;
  int? get ringBattery => _ringBattery;
  int? get ringMillivolts => _ringMillivolts;
  List<int> get recentMoves => List<int>.unmodifiable(_recentMoves);
  Stream<MonitorPhase> get changes => _changes.stream;
  bool get connected => _connected;
  DateTime? get lastLineAt => _lastLineAt;
  DateTime? get lastHeartbeatAt => _lastHeartbeatAt;

  /// Son [count] sinyalin moves değerleri (olay anı görüntüsü).
  List<int> snapshot([int count = K.snapshotCount]) => _recentMoves.length <= count
      ? List<int>.of(_recentMoves)
      : _recentMoves.sublist(_recentMoves.length - count);

  void _set(MonitorPhase p) {
    _phase = p;
    _changes.add(p);
  }

  // ---------------------------------------------------------------- girişler

  /// Yüzükten gelen bir mesajı işler ve ardından [tick] çağırır.
  void handle(RingMessage m) {
    final now = clock.now();
    _lastLineAt = now;
    if (!_connected) ringConnected();
    switch (m) {
      case Heartbeat():
        _onHeartbeat(m, now);
      case SosMessage():
        _onSos(m, now);
      case TremorMessage():
        _onTremor(m, now);
      case VersionMessage():
      case RawMessage():
        break;
    }
    tick();
  }

  void _onHeartbeat(Heartbeat hb, DateTime now) {
    _lastHeartbeatAt = now;
    final last = _lastSeq;
    if (last != null) {
      final expected = (last + 1) % 256;
      if (hb.seq != expected && hb.seq != last) {
        final lost = (hb.seq - expected) % 256;
        _events.log(EventKind.packetLoss, '$lost sinyal kayboldu');
      }
    }
    _lastSeq = hb.seq;

    _onBattery(hb, now);

    final s = _settings();
    final moving = hb.moves >= s.minMoves;
    final before = List<int>.of(_recentMoves);
    _recentMoves.add(hb.moves);
    while (_recentMoves.length > K.recentMovesCount) {
      _recentMoves.removeAt(0);
    }
    if (moving) _lastMotionAt = now;

    final p = _phase;
    switch (p) {
      case Paused():
        if (moving && now.difference(p.since) >= K.pauseMinBeforeAutoResume) {
          _resumeInternal(auto: true);
        }
      case Watching():
        if (!moving) {
          _set(Counting(since: now, abrupt: isAbrupt(before)));
        }
      case Counting():
        if (moving) _set(const Watching());
      case PreAlarm():
        // KARAR: Ön uyarıda hareket iptal sebebi değildir (istemsiz hareket olabilir).
        if (moving && !p.motionSeen) _set(p.copyWith(motionSeen: true));
      case AlarmActive():
        break;
    }
  }

  /// Hareketsizlikten önceki son 6 sinyale göre durmanın ani olup olmadığı.
  static bool isAbrupt(List<int> previous) {
    if (previous.isEmpty) return false;
    final window = previous.length <= K.abruptLookback
        ? previous
        : previous.sublist(previous.length - K.abruptLookback);
    final lastActive = window.last >= K.activeMoves;
    final activeCount = window.where((m) => m >= K.activeMoves).length;
    return lastActive && activeCount >= K.abruptMinActive;
  }

  void _onBattery(Heartbeat hb, DateTime now) {
    if (hb.millivolts < K.ringBatteryNoBatteryMv) return;
    _ringBattery = hb.percent;
    _ringMillivolts = hb.millivolts;
    battery.add(now, hb.percent);
    if (hb.percent > K.ringBatteryReset) {
      _bat20 = false;
      _bat10 = false;
    }
    if (hb.percent < K.ringBatteryWarn2 && !_bat10) {
      _bat10 = true;
      _bat20 = true;
      _lowBattery(hb.percent);
    } else if (hb.percent < K.ringBatteryWarn1 && !_bat20) {
      _bat20 = true;
      _lowBattery(hb.percent);
    }
  }

  void _lowBattery(int pct) {
    _events.log(EventKind.lowBattery, 'Yüzük pili %$pct');
    _events.notify(AppNotification(
      AppNotificationKind.lowBattery,
      title: 'Yüzük pili %$pct',
      body: 'Yüzüğü kısa süre şarj etmeyi unutma.',
    ));
  }

  bool _duplicate(int seq, int? lastSeq, DateTime? lastAt, DateTime now) =>
      lastSeq == seq && lastAt != null && now.difference(lastAt) < K.sosDedupWindow;

  void _onSos(SosMessage m, DateTime now) {
    if (_duplicate(m.seq, _lastSosSeq, _lastSosAt, now)) return;
    _lastSosSeq = m.seq;
    _lastSosAt = now;
    final s = _settings();
    if (!s.armed) return;
    final p = _phase;
    final sosDeadline = now.add(Duration(seconds: s.sosCancelSeconds));
    switch (p) {
      case Paused():
      case Watching():
      case Counting():
        _events.log(EventKind.sos, 'Yüzüğe üç kez vuruldu');
        _set(PreAlarm(reason: const Sos(), deadline: sosDeadline, startedAt: now));
      case PreAlarm():
        _events.log(EventKind.sos, 'Ön uyarı sırasında yüzüğe vuruldu');
        if (sosDeadline.isBefore(p.deadline)) _set(p.copyWith(deadline: sosDeadline));
      case AlarmActive():
        _events.log(EventKind.sos, 'Alarm açıkken tekrar yardım istendi');
        _alarms.extraSos();
    }
  }

  void _onTremor(TremorMessage m, DateTime now) {
    if (_duplicate(m.seq, _lastTrmSeq, _lastTrmAt, now)) return;
    _lastTrmSeq = m.seq;
    _lastTrmAt = now;
    final s = _settings();
    _events.log(EventKind.tremor, 'Uzun süreli titreme algılandı');
    if (!s.armed) return;
    final p = _phase;
    if (p is Watching || p is Counting) {
      _set(PreAlarm(
        reason: const Tremor(),
        deadline: now.add(Duration(seconds: s.preAlarmSeconds)),
        startedAt: now,
      ));
    }
  }

  // ---------------------------------------------------------------- zaman

  /// Zamana bağlı geçişleri değerlendirir.
  void tick() {
    final now = clock.now();
    final s = _settings();

    final lastLine = _lastLineAt;
    if (_connected && lastLine != null && now.difference(lastLine) > K.staleSignal) {
      ringDisconnected();
    }

    final disc = _disconnectedAt;
    if (!_connected &&
        disc != null &&
        !_disconnectNotified &&
        _phase is! Paused &&
        now.difference(disc) >= K.disconnectNotifyDelay) {
      _disconnectNotified = true;
      _events.notify(const AppNotification(
        AppNotificationKind.disconnected,
        title: 'Yüzük bağlantısı koptu',
        body: 'Yüzük yakında ve şarjlı mı? Bağlantı gelince koruma kendiliğinden sürer.',
      ));
    }

    final p = _phase;
    switch (p) {
      case Paused():
        if (!now.isBefore(p.until)) _resumeInternal(auto: true);
      case Counting():
        if (!_connected || !s.armed) return;
        final limit = SleepSchedule.limit(s, now, abrupt: p.abrupt);
        if (now.difference(p.since) >= limit) {
          final minutes = SleepSchedule.limitMinutes(s, now, abrupt: p.abrupt);
          _set(PreAlarm(
            reason: Inactivity(minutes: minutes, abrupt: p.abrupt),
            deadline: now.add(Duration(seconds: s.preAlarmSeconds)),
            startedAt: now,
          ));
        }
      case PreAlarm():
        // KARAR: Deadline geçmişse ve iptal edilmediyse alarm her zaman gönderilir,
        // iOS'ta tick gecikmiş olsa bile (gerçek alarmı asla kaçırmamak için).
        if (!now.isBefore(p.deadline)) _escalate(p);
      case Watching():
      case AlarmActive():
        break;
    }
  }

  void _escalate(PreAlarm p) {
    final s = _settings();
    final reason = p.reason;
    final record = AlarmRecord(
      id: _newId(),
      reason: reason,
      triggeredAt: clock.now(),
      lastMotionAt: _lastMotionAt,
      ringBattery: _ringBattery,
      preAlarmSeconds: reason is Sos ? s.sosCancelSeconds : s.preAlarmSeconds,
    );
    _events.log(EventKind.preAlarmEscalated, _reasonText(reason));
    _set(AlarmActive(record));
    _alarms.dispatch(record);
  }

  // ---------------------------------------------------------------- komutlar

  /// Ön uyarıyı iptal eder ya da (UI onayından sonra) aktif alarmı kapatır.
  void imFine() {
    final p = _phase;
    final now = clock.now();
    if (p is PreAlarm) {
      _lastMotionAt = now;
      _events.log(EventKind.preAlarmCancelled, _reasonText(p.reason));
      _set(const Watching());
    } else if (p is AlarmActive) {
      _lastMotionAt = now;
      _alarms.close(byUser: true);
      _events.log(EventKind.alarmClosed, 'İyi olduğunu bildirdi');
      _set(const Watching());
    }
  }

  /// Ön uyarıdayken geri sayımı beklemeden alarmı gönderir.
  void sendNow() {
    final p = _phase;
    if (p is PreAlarm) _escalate(p);
  }

  /// Ana ekrandaki "Yardım çağır": ön uyarısız, doğrudan alarm.
  void requestHelp() {
    if (_phase is AlarmActive) return;
    final record = AlarmRecord(
      id: _newId(),
      reason: const Manual(),
      triggeredAt: clock.now(),
      lastMotionAt: _lastMotionAt,
      ringBattery: _ringBattery,
    );
    _events.log(EventKind.manualHelp, 'Uygulamadan yardım istendi');
    _set(AlarmActive(record));
    _alarms.dispatch(record);
  }

  /// Korumayı [d] kadar duraklatır (ön uyarı / alarm sırasında yok sayılır).
  void pause(Duration d) {
    if (_phase is PreAlarm || _phase is AlarmActive) return;
    final now = clock.now();
    _events.log(EventKind.paused, 'Duraklatıldı, ${d.inMinutes} dk');
    _set(Paused(until: now.add(d), since: now));
  }

  /// Duraklatmayı elle bitirir.
  void resume() {
    if (_phase is Paused) _resumeInternal(auto: false);
  }

  void _resumeInternal({required bool auto}) {
    _lastMotionAt = clock.now();
    _events.log(EventKind.resumed, auto ? 'Koruma kendiliğinden açıldı' : 'Koruma devam ediyor');
    if (auto) {
      _events.notify(const AppNotification(
        AppNotificationKind.protectionBack,
        title: 'Koruma tekrar açık',
        body: 'Yüzük seni yeniden izliyor.',
      ));
    }
    _set(const Watching());
  }

  /// Yüzük bağlandı: eski veriyle alarm verilmez, sayım sıfırdan başlar.
  void ringConnected() {
    final now = clock.now();
    final wasConnected = _connected;
    _connected = true;
    _lastLineAt = now;
    _disconnectedAt = null;
    if (_disconnectNotified) {
      _events.cancel(const AppNotification.ref(AppNotificationKind.disconnected));
    }
    _disconnectNotified = false;
    if (wasConnected) return;
    _events.log(EventKind.ringConnected, 'Yüzük bağlandı');
    final p = _phase;
    if (p is Counting) _set(const Watching());
    if (p is Watching || p is Counting) _lastMotionAt = now;
  }

  /// Yüzük bağlantısı koptu: sayım durur, gruba asla alarm gitmez.
  void ringDisconnected() {
    if (!_connected) return;
    _connected = false;
    _disconnectedAt = clock.now();
    _disconnectNotified = false;
    _lastSeq = null;
    _events.log(EventKind.ringDisconnected, 'Yüzük bağlantısı koptu');
    if (_phase is Counting) _set(const Watching());
  }

  /// Bekleyen bir alarm diskten geri yüklendiğinde fazı eşitler.
  void restoreAlarm(AlarmRecord r) {
    if (_phase is! AlarmActive) _set(AlarmActive(r));
  }

  static String _reasonText(AlarmReason r) => switch (r) {
        Inactivity(:final minutes, :final abrupt) =>
          '$minutes dk hareketsizlik${abrupt ? ' (ani)' : ''}',
        Sos() => 'Yüzüğe üç kez vuruldu',
        Tremor() => 'Uzun süreli titreme',
        Manual() => 'Uygulamadan yardım',
      };

  Future<void> dispose() => _changes.close();
}
