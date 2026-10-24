import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/alarm_reason.dart';
import '../core/alarm_record.dart';
import '../core/constants.dart';
import '../core/events.dart';
import '../core/health_check.dart';
import '../core/message_composer.dart';
import '../core/monitor.dart';
import '../core/monitor_phase.dart';
import '../core/ring_protocol.dart';
import '../data/app_logger.dart';
import '../data/contacts_repository.dart';
import '../data/event_log.dart';
import '../data/pending_alarm_store.dart';
import '../data/secure_token_store.dart';
import '../data/settings_repository.dart';
import 'alarm_dispatcher.dart';
import 'background/background_host.dart';
import 'background/background_task_runner.dart';
import 'location/location_provider.dart';
import 'notify/notification_service.dart';
import 'ring/ble_ring_transport.dart';
import 'ring/ring_transport.dart';
import 'ring/simulated_ring_transport.dart';
import 'ring/switchable_ring_transport.dart';
import 'sms/sms_sender.dart';
import 'system_channel.dart';
import 'telegram/telegram_client.dart';
import 'telegram/telegram_sender.dart';

/// UI'nın okuduğu anlık çekirdek görünümü.
class CoreView {
  const CoreView({
    required this.phase,
    required this.lastMotionAt,
    required this.ringBattery,
    required this.ringMillivolts,
    required this.recentMoves,
    required this.connection,
    required this.rssi,
    required this.lastSignalAt,
    required this.deviceName,
    required this.delivery,
    required this.record,
    required this.shield,
    required this.issues,
    required this.batteryRemaining,
    required this.lastFullAt,
    required this.heartbeatCount,
  });

  final MonitorPhase phase;
  final DateTime lastMotionAt;
  final int? ringBattery;
  final int? ringMillivolts;
  final List<int> recentMoves;
  final RingConnectionState connection;
  final int? rssi;
  final DateTime? lastSignalAt;
  final String? deviceName;
  final DeliveryState delivery;
  final AlarmRecord? record;
  final ShieldLevel shield;
  final List<HealthIssue> issues;
  final Duration? batteryRemaining;
  final DateTime? lastFullAt;

  /// Her yeni HB'de artar (dalga "nabız" animasyonu için).
  final int heartbeatCount;
}

/// Bütün servisleri birbirine bağlayan, UI olmadan da çalışan çekirdek denetleyici.
///
/// Monitor tek karar noktasıdır; AppCore yalnızca veri taşır ve komut iletir.
class AppCore implements MonitorEvents {
  AppCore({
    required AppSettings Function() settings,
    required Future<void> Function(AppSettings Function(AppSettings)) updateSettings,
    required SharedPreferences prefs,
    required SecureTokenStore tokens,
    required ContactsRepository contacts,
    required EventLog eventLog,
    required SwitchableRingTransport transport,
    required TelegramSender telegram,
    required LocationProvider location,
    required SmsSender sms,
    required NotificationService notifications,
    required BackgroundHost background,
    required BackgroundTaskRunner backgroundTask,
    required PendingAlarmStore pendingStore,
  })  : _settings = settings,
        _updateSettings = updateSettings,
        _prefs = prefs,
        tokens = tokens,
        contacts = contacts,
        eventLog = eventLog,
        transport = transport,
        telegram = telegram,
        location = location,
        sms = sms,
        notifications = notifications,
        background = background {
    dispatcher = AlarmDispatcher(
      settings: () => _settings().toDispatchSettings(),
      token: tokens.read,
      contacts: contacts.all,
      telegram: telegram,
      location: location,
      sms: sms,
      store: pendingStore,
      events: this,
      backgroundTask: backgroundTask,
    );
    monitor = Monitor(
      settings: () => _settings().toMonitorSettings(),
      alarms: dispatcher,
      events: this,
    );
  }

  final AppSettings Function() _settings;
  final Future<void> Function(AppSettings Function(AppSettings)) _updateSettings;
  final SharedPreferences _prefs;
  final SecureTokenStore tokens;
  final ContactsRepository contacts;
  final EventLog eventLog;
  final SwitchableRingTransport transport;
  final TelegramSender telegram;
  final LocationProvider location;
  final SmsSender sms;
  final NotificationService notifications;
  final BackgroundHost background;

  late final AlarmDispatcher dispatcher;
  late final Monitor monitor;

  final _changes = StreamController<void>.broadcast();
  final _messages = StreamController<RingMessage>.broadcast();
  final _actions = StreamController<String>.broadcast();
  final _health = HealthCheck();
  final _battery = Battery();

  Timer? _timer;
  bool _started = false;
  bool _healthBusy = false;
  int _secs = 0;
  int _heartbeats = 0;
  String? _ongoingText;
  DateTime? _lastPreAlarmNotify;
  PreAlarm? _shownPreAlarm;
  int? _phoneBattery;
  bool _phoneCharging = false;
  int _contactsCount = 0;
  bool _rehearsalActive = false;

  /// UI'ya "yeniden çiz" sinyali (en az saniyede bir).
  Stream<void> get changes => _changes.stream;

  /// Yüzükten gelen ayrıştırılmış mesajlar (eşleştirme / kalibrasyon ekranları).
  Stream<RingMessage> get messages => _messages.stream;

  /// Bildirim eylemleri (UI'nın tam ekran rotayı açması için).
  Stream<String> get notificationActions => _actions.stream;

  ShieldLevel get shield => _health.level;
  List<HealthIssue> get issues => _health.issues;
  bool get isAndroid => Platform.isAndroid;

  CoreView get view => CoreView(
        phase: monitor.phase,
        lastMotionAt: monitor.lastMotionAt,
        ringBattery: monitor.ringBattery,
        ringMillivolts: monitor.ringMillivolts,
        recentMoves: monitor.recentMoves,
        connection: transport.currentState,
        rssi: transport.rssi,
        lastSignalAt: monitor.lastLineAt,
        deviceName: transport.deviceName,
        delivery: dispatcher.state,
        record: dispatcher.current,
        shield: _health.level,
        issues: _health.issues,
        batteryRemaining: monitor.battery.estimateRemaining(),
        lastFullAt: monitor.battery.lastFullAt,
        heartbeatCount: _heartbeats,
      );

  void _changed() {
    if (!_changes.isClosed) _changes.add(null);
  }

  // ------------------------------------------------------------ yaşam döngüsü

  /// UI çizilmeden önce `main()` içinde çağrılır.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await notifications.init(_onNotificationAction);

    final s = _settings();
    if (s.simulatedRing) await _useSimulated(true);
    transport.savedId = s.simulatedRing ? null : s.savedRingId;
    transport.onPaired = (id) {
      if (id == 'SIMULATED') return;
      unawaited(_updateSettings((x) => x.copyWith(savedRingId: id)));
    };
    transport.state.listen(_onTransportState);
    transport.lines.listen(_onLine);
    monitor.changes.listen(_onPhase);
    dispatcher.delivery.listen((_) => _changed());

    await eventLog.purgeOld();
    await _checkProtectionGap();

    final pending = await dispatcher.resumePendingIfAny();
    if (pending != null) monitor.restoreAlarm(pending);

    _contactsCount = (await contacts.all()).length;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onSecond());

    await startRing();
    if (s.onboardingDone) await background.start(_ongoingLabel());
    unawaited(refreshHealth());
  }

  /// Yüzük taşıyıcısını başlatır (izinler verildikten sonra tekrar çağrılabilir).
  Future<void> startRing() async {
    try {
      await transport.stop();
      await transport.start();
    } on Object catch (e) {
      AppLogger.w('Yüzük başlatılamadı: $e');
    }
  }

  Future<void> _checkProtectionGap() async {
    final last = _prefs.getString('lastAliveAt');
    final at = last == null ? null : DateTime.tryParse(last);
    if (at != null && _settings().onboardingDone) {
      final gap = clock.now().difference(at);
      if (gap >= const Duration(minutes: 3)) {
        await eventLog.add(EventKind.protectionGap, 'Koruma ${gap.inMinutes} dk kesildi', const []);
      }
    }
    await _prefs.setString('lastAliveAt', clock.now().toIso8601String());
  }

  void _onSecond() {
    _secs++;
    monitor.tick();
    dispatcher.tick();
    _refreshPreAlarmNotification();
    if (_secs % 5 == 0) unawaited(refreshHealth());
    if (_secs % 60 == 0) unawaited(_prefs.setString('lastAliveAt', clock.now().toIso8601String()));
    _changed();
  }

  /// Uygulama yaşam döngüsü (UI'dan iletilir).
  Future<void> onLifecycle(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await notifications.cancelProtectionStopped();
      if (transport.currentState == RingConnectionState.unauthorized ||
          transport.currentState == RingConnectionState.bluetoothOff) {
        await startRing();
      }
      _contactsCount = (await contacts.all()).length;
      if (_settings().onboardingDone) await background.ensureForegroundCapabilities(_ongoingLabel());
      await checkTelegramIfDue();
      await refreshHealth();
    }
    // iOS'ta "Koruma durdu" bildirimi AppDelegate.applicationWillTerminate'te zamanlanır.
  }

  // ------------------------------------------------------------ yüzük

  void _onTransportState(RingConnectionState s) {
    if (s == RingConnectionState.connected) {
      monitor.ringConnected();
      unawaited(transport.send(RingProtocol.versionQuery));
      unawaited(_sendCfg());
    } else if (s == RingConnectionState.disconnected ||
        s == RingConnectionState.bluetoothOff ||
        s == RingConnectionState.searching) {
      monitor.ringDisconnected();
    }
    unawaited(refreshHealth());
    _changed();
  }

  void _onLine(String line) {
    final m = RingProtocol.parse(line);
    if (m == null) return;
    switch (m) {
      case Heartbeat():
        _heartbeats++;
      case SosMessage(:final seq):
        unawaited(transport.send(RingProtocol.ack(seq)));
      case TremorMessage(:final seq):
        unawaited(transport.send(RingProtocol.ack(seq)));
      case VersionMessage(:final version):
        if (_settings().firmwareVersion != version) {
          unawaited(_updateSettings((x) => x.copyWith(firmwareVersion: version)).then((_) => _sendCfg()));
        }
      case RawMessage():
        break;
    }
    _messages.add(m);
    monitor.handle(m);
    // iOS'ta arka planda zamanlayıcı yok: her satır bir kontrol anıdır.
    dispatcher.tick();
    _changed();
  }

  /// Hassasiyeti yüzüğe gönderir (firmware ≥ 0.2).
  Future<void> _sendCfg() async {
    final s = _settings();
    if (!s.firmwareSupportsCommands || !transport.hasRx) return;
    await transport.send(RingProtocol.cfg(s.cfgThreshold, K.heartbeatInterval.inSeconds));
  }

  Future<void> setRaw({required bool on}) => transport.send(RingProtocol.raw(on: on));

  Future<void> _useSimulated(bool on) async {
    if (on && transport.inner is! SimulatedRingTransport) {
      await transport.swap(SimulatedRingTransport()..fast = _settings().simFast);
    } else if (!on && transport.inner is! BleRingTransport) {
      final ble = BleRingTransport()..savedId = _settings().savedRingId;
      await transport.swap(ble);
    }
  }

  SimulatedRingTransport? get simulator {
    final t = transport.inner;
    return t is SimulatedRingTransport ? t : null;
  }

  /// "Yüzüğü unut ve yeniden eşleştir".
  Future<void> forgetRing() async {
    await _updateSettings((x) => x.copyWith(clearSavedRingId: true));
    await transport.forgetAndRescan();
  }

  // ------------------------------------------------------------ ayar değişimi

  /// Ayarlar değiştiğinde çağrılır (provider dinleyicisi).
  Future<void> onSettingsChanged(AppSettings? prev, AppSettings next) async {
    if (prev == null) return;
    if (prev.sensitivity != next.sensitivity) await _sendCfg();
    if (prev.sleepEnabled != next.sleepEnabled) {
      log(next.sleepEnabled ? EventKind.sleepOn : EventKind.sleepOff,
          next.sleepEnabled ? 'Uyku modu açıldı' : 'Uyku modu kapandı');
    }
    if (prev.simulatedRing != next.simulatedRing) {
      await _useSimulated(next.simulatedRing);
      await startRing();
    }
    if (prev.simFast != next.simFast) simulator?.fast = next.simFast;
    if (!prev.onboardingDone && next.onboardingDone) {
      await background.start(_ongoingLabel(), foreground: true);
      await notifications.cancelPreAlarm();
    }
    unawaited(refreshHealth());
    _changed();
  }

  // ------------------------------------------------------------ faz

  void _onPhase(MonitorPhase p) {
    if (p is PreAlarm) {
      final prev = _shownPreAlarm;
      if (prev == null || prev.deadline != p.deadline || prev.motionSeen != p.motionSeen) {
        _shownPreAlarm = p;
        _lastPreAlarmNotify = clock.now();
        unawaited(notifications.schedulePreAlarm(p.reason, p.deadline, motionSeen: p.motionSeen));
      }
    } else if (_shownPreAlarm != null) {
      _shownPreAlarm = null;
      unawaited(notifications.cancelPreAlarm());
    }
    _updateOngoing();
    _changed();
  }

  /// Android: ön uyarı bildirimi 10 sn'de bir yenilenir (ses + titreşim tekrarlar).
  void _refreshPreAlarmNotification() {
    final p = monitor.phase;
    final last = _lastPreAlarmNotify;
    if (p is! PreAlarm || !Platform.isAndroid || last == null) return;
    if (clock.now().difference(last) >= K.preAlarmRepeat) {
      _lastPreAlarmNotify = clock.now();
      unawaited(notifications.schedulePreAlarm(p.reason, p.deadline, motionSeen: p.motionSeen));
    }
  }

  String _ongoingLabel() {
    final p = monitor.phase;
    if (!_settings().onboardingDone) return 'Kurulum bitmedi · koruma kapalı';
    if (p is PreAlarm) return 'Ön uyarı · cevabın bekleniyor';
    if (p is AlarmActive) return 'Yakınlarına haber verildi';
    if (p is Paused) return 'Duraklatıldı · ${MessageComposer.hhmm(p.until)} kadar';
    switch (transport.currentState) {
      case RingConnectionState.searching:
      case RingConnectionState.connecting:
        return 'Yüzük aranıyor';
      case RingConnectionState.disconnected:
        return 'Yüzük bağlı değil';
      case RingConnectionState.bluetoothOff:
        return 'Bluetooth kapalı';
      case RingConnectionState.unauthorized:
        return 'Bluetooth izni yok';
      case RingConnectionState.connected:
        break;
    }
    if (_health.level == ShieldLevel.protected) return 'Koruma açık';
    final first = _health.issues.isEmpty ? null : _health.issues.first;
    return first == null ? 'Koruma açık' : 'Dikkat · ${first.title}';
  }

  void _updateOngoing() {
    final t = _ongoingLabel();
    if (t == _ongoingText) return;
    _ongoingText = t;
    unawaited(background.update(t));
  }

  // ------------------------------------------------------------ komutlar

  void imFine() {
    monitor.imFine();
    _changed();
  }

  void sendNow() {
    monitor.sendNow();
    _changed();
  }

  void requestHelp() {
    monitor.requestHelp();
    _changed();
  }

  void pause(Duration d) {
    monitor.pause(d);
    unawaited(refreshHealth());
    _changed();
  }

  void resume() {
    monitor.resume();
    unawaited(refreshHealth());
    _changed();
  }

  Future<void> restartBackground() async {
    await background.stop();
    await background.start(_ongoingLabel(), foreground: true);
    await refreshHealth();
  }

  void _onNotificationAction(String action) {
    AppLogger.i('Bildirim eylemi: $action');
    if (action == NotificationActions.imFine) {
      if (monitor.phase is PreAlarm) monitor.imFine();
    } else if (action == NotificationActions.sendNow) {
      if (monitor.phase is PreAlarm) monitor.sendNow();
    }
    if (!_actions.isClosed) _actions.add(action);
    _changed();
  }

  // ------------------------------------------------------------ prova

  bool get rehearsalActive => _rehearsalActive;

  Future<void> startRehearsalNotification(DateTime deadline) async {
    _rehearsalActive = true;
    await notifications.schedulePreAlarm(
      Inactivity(minutes: _settings().abruptMinutes, abrupt: true),
      deadline,
      rehearsal: true,
    );
  }

  Future<void> refreshRehearsalNotification(DateTime deadline) async {
    if (!_rehearsalActive || !Platform.isAndroid) return;
    await notifications.schedulePreAlarm(
      Inactivity(minutes: _settings().abruptMinutes, abrupt: true),
      deadline,
      rehearsal: true,
    );
  }

  Future<void> stopRehearsalNotification() async {
    _rehearsalActive = false;
    await notifications.cancelPreAlarm();
  }

  /// Provanın sonunda gruba [TEST] alarmı (metin + tek konum, canlı değil, SMS yok).
  Future<String?> sendRehearsalMessage() async {
    final s = _settings();
    final token = await tokens.read() ?? '';
    if (token.isEmpty || s.chatId.isEmpty) return 'Telegram ayarları eksik';
    final now = clock.now();
    final record = AlarmRecord(
      id: 'test',
      reason: Inactivity(minutes: s.abruptMinutes, abrupt: true),
      triggeredAt: now,
      lastMotionAt: now.subtract(Duration(minutes: s.abruptMinutes)),
      ringBattery: monitor.ringBattery,
      preAlarmSeconds: K.rehearsalSeconds,
    );
    final cs = await contacts.all();
    final c = await location.current(timeout: K.locationTimeout);
    try {
      final text = MessageComposer.alarm(
        record: record,
        name: s.personName,
        location: c,
        firstContact: cs.isEmpty ? null : cs.first,
        test: true,
      );
      await telegram.sendMessage(token, s.chatId, text);
      final tg = telegram;
      if (c != null && tg is TelegramClient) await tg.sendStaticLocation(token, s.chatId, c);
      return null;
    } on TelegramException catch (e) {
      return e.userMessage;
    }
  }

  // ------------------------------------------------------------ Telegram

  /// Ayarlardaki / kurulumdaki "Test mesajı gönder". Hata yoksa `null`.
  Future<String?> sendTelegramTest({String? token, String? chatId}) async {
    final s = _settings();
    final t = token ?? await tokens.read() ?? '';
    final c = chatId ?? s.chatId;
    if (t.isEmpty) return 'Bot token boş';
    if (c.isEmpty) return 'Grup chat ID boş';
    try {
      await telegram.getMe(t);
      await telegram.sendMessage(t, c, MessageComposer.settingsTest(s.personName));
      await _updateSettings((x) => x.copyWith(lastTelegramCheckAt: clock.now(), lastTelegramCheckOk: true));
      unawaited(refreshHealth());
      return null;
    } on TelegramException catch (e) {
      AppLogger.w('Telegram testi başarısız: ${e.code}');
      await _updateSettings((x) => x.copyWith(lastTelegramCheckAt: clock.now(), lastTelegramCheckOk: false));
      unawaited(refreshHealth());
      return e.userMessage;
    }
  }

  /// Günde bir kez sessiz `getMe`.
  Future<void> checkTelegramIfDue() async {
    final s = _settings();
    final last = s.lastTelegramCheckAt;
    if (last != null && clock.now().difference(last) < K.telegramCheckEvery) return;
    final t = await tokens.read() ?? '';
    if (t.isEmpty) return;
    var ok = true;
    try {
      await telegram.getMe(t);
    } on TelegramException catch (e) {
      // Ağ yoksa (code 0) token'ı suçlama; sonraki açılışta yeniden denenir.
      if (e.code == 0) return;
      ok = false;
      log(EventKind.telegramCheckFailed, e.userMessage);
    }
    await _updateSettings((x) => x.copyWith(lastTelegramCheckAt: clock.now(), lastTelegramCheckOk: ok));
  }

  /// Yalnızca kendi numarana test SMS'i.
  Future<bool> sendTestSms(String phone) =>
      sms.send([phone], MessageComposer.smsTest(_settings().personName));

  // ------------------------------------------------------------ sağlık

  Future<void> refreshHealth() async {
    if (_healthBusy) return;
    _healthBusy = true;
    try {
      final s = _settings();
      final android = Platform.isAndroid;
      final token = await tokens.read() ?? '';
      final locAuth = await location.status();
      final precise = locAuth == LocationAuth.denied ? false : await location.precise();
      try {
        _phoneBattery = await _battery.batteryLevel;
        final st = await _battery.batteryState;
        _phoneCharging = st == BatteryState.charging || st == BatteryState.full;
      } on Object catch (_) {}
      final p = monitor.phase;
      final bt = switch (transport.currentState) {
        RingConnectionState.bluetoothOff => BtStatus.off,
        RingConnectionState.unauthorized => BtStatus.unauthorized,
        _ => BtStatus.on,
      };
      _health.evaluate(HealthInputs(
        now: clock.now(),
        isAndroid: android,
        bluetooth: bt,
        lastLineAt: monitor.connected ? monitor.lastLineAt : null,
        notificationsGranted: await notifications.notificationsGranted(),
        telegramConfigured: token.isNotEmpty && s.chatId.isNotEmpty,
        telegramLastCheckOk: s.lastTelegramCheckOk,
        foregroundServiceRunning: await background.isRunning(),
        onboardingDone: s.onboardingDone,
        batteryOptimizationExempt: !android || await Permission.ignoreBatteryOptimizations.isGranted,
        fullScreenAllowed: await SystemChannel.canUseFullScreenIntent(),
        locationAlways: android ? locAuth != LocationAuth.denied : locAuth == LocationAuth.always,
        locationPrecise: precise,
        ringBattery: monitor.ringBattery,
        phoneBattery: _phoneBattery,
        phoneCharging: _phoneCharging,
        contactsCount: _contactsCount,
        pausedUntil: p is Paused ? p.until : null,
      ));
      _updateOngoing();
      _changed();
    } on Object catch (e) {
      AppLogger.e('Sağlık kontrolü', e);
    } finally {
      _healthBusy = false;
    }
  }

  Future<void> contactsChanged() async {
    _contactsCount = (await contacts.all()).length;
    await refreshHealth();
  }

  // ------------------------------------------------------------ MonitorEvents

  @override
  void log(EventKind k, String detail, {bool sentToGroup = false}) {
    AppLogger.i('Olay ${k.name}: $detail');
    unawaited(eventLog.add(k, detail, monitor.snapshot(), sentToGroup: sentToGroup));
  }

  @override
  void notify(AppNotification n) => unawaited(notifications.show(n));

  @override
  void cancel(AppNotification n) => unawaited(notifications.cancel(n));

  Future<void> dispose() async {
    _timer?.cancel();
    await _changes.close();
    await _messages.close();
    await _actions.close();
  }
}
