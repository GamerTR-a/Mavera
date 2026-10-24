import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../core/monitor_settings.dart';
import '../services/alarm_dispatcher.dart';

/// Kullanıcı ayarları (değişmez değer nesnesi).
class AppSettings {
  const AppSettings({
    this.personName = defaultName,
    this.welcomeMessage = defaultWelcome,
    this.chatId = '',
    this.abruptMinutes = 3,
    this.gradualMinutes = 10,
    this.preAlarmSeconds = 60,
    this.sosCancelSeconds = 15,
    this.sensitivity = Sensitivity.medium,
    this.sleepEnabled = false,
    this.sleepScheduleEnabled = false,
    this.sleepStart = 1410,
    this.sleepEnd = 450,
    this.sleepMinutes = 30,
    this.smsMode = SmsMode.fallback,
    this.smsFallbackSeconds = 60,
    this.onboardingDone = false,
    this.lastTelegramCheckAt,
    this.lastTelegramCheckOk,
    this.savedRingId,
    this.firmwareVersion,
    this.simulatedRing = false,
    this.simFast = false,
  });

  static const defaultName = 'Meryem';
  static const defaultWelcome =
      'Bu yüzüğü senin için yaptım. Bir şey olursa artık yalnız kalmayacaksın.';

  // Önerilen değerler (Süreler ekranı).
  static const recAbrupt = 3;
  static const recGradual = 10;
  static const recPreAlarm = 60;
  static const recSos = 15;

  final String personName;
  final String welcomeMessage;
  final String chatId;
  final int abruptMinutes;
  final int gradualMinutes;
  final int preAlarmSeconds;
  final int sosCancelSeconds;
  final Sensitivity sensitivity;
  final bool sleepEnabled;
  final bool sleepScheduleEnabled;
  final int sleepStart;
  final int sleepEnd;
  final int sleepMinutes;
  final SmsMode smsMode;
  final int smsFallbackSeconds;
  final bool onboardingDone;
  final DateTime? lastTelegramCheckAt;
  final bool? lastTelegramCheckOk;
  final String? savedRingId;
  final String? firmwareVersion;

  /// Yalnızca debug: BLE yerine simüle yüzük.
  final bool simulatedRing;

  /// Yalnızca debug: zamanı ×10 hızlandır.
  final bool simFast;

  /// Hassasiyete göre `minMoves` (firmware ≥ 0.2'de eşik yüzükte, minMoves 3).
  int get minMoves {
    if (firmwareSupportsCommands) return K.minMovesMedium;
    return switch (sensitivity) {
      Sensitivity.low => K.minMovesLow,
      Sensitivity.medium => K.minMovesMedium,
      Sensitivity.high => K.minMovesHigh,
    };
  }

  bool get firmwareSupportsCommands {
    final v = firmwareVersion;
    if (v == null) return false;
    final p = v.split('.');
    final ma = int.tryParse(p.first) ?? 0;
    final mi = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
    return ma > 0 || mi >= 2;
  }

  /// Hassasiyete göre `CFG` eşiği (milli-g).
  int get cfgThreshold => switch (sensitivity) {
        Sensitivity.low => 40,
        Sensitivity.medium => 25,
        Sensitivity.high => 15,
      };

  MonitorSettings toMonitorSettings() => MonitorSettings(
        abruptMinutes: abruptMinutes,
        gradualMinutes: gradualMinutes,
        preAlarmSeconds: preAlarmSeconds,
        sosCancelSeconds: sosCancelSeconds,
        minMoves: minMoves,
        sleepEnabled: sleepEnabled,
        sleepScheduleEnabled: sleepScheduleEnabled,
        sleepStart: sleepStart,
        sleepEnd: sleepEnd,
        sleepMinutes: sleepMinutes,
        armed: onboardingDone,
        timeScale: simulatedRing && simFast ? 10 : 1,
      );

  DispatchSettings toDispatchSettings() => DispatchSettings(
        personName: personName,
        chatId: chatId,
        smsMode: smsMode,
        smsFallbackSeconds: smsFallbackSeconds,
      );

  AppSettings copyWith({
    String? personName,
    String? welcomeMessage,
    String? chatId,
    int? abruptMinutes,
    int? gradualMinutes,
    int? preAlarmSeconds,
    int? sosCancelSeconds,
    Sensitivity? sensitivity,
    bool? sleepEnabled,
    bool? sleepScheduleEnabled,
    int? sleepStart,
    int? sleepEnd,
    int? sleepMinutes,
    SmsMode? smsMode,
    int? smsFallbackSeconds,
    bool? onboardingDone,
    DateTime? lastTelegramCheckAt,
    bool? lastTelegramCheckOk,
    String? savedRingId,
    bool clearSavedRingId = false,
    String? firmwareVersion,
    bool? simulatedRing,
    bool? simFast,
  }) =>
      AppSettings(
        personName: personName ?? this.personName,
        welcomeMessage: welcomeMessage ?? this.welcomeMessage,
        chatId: chatId ?? this.chatId,
        abruptMinutes: abruptMinutes ?? this.abruptMinutes,
        gradualMinutes: gradualMinutes ?? this.gradualMinutes,
        preAlarmSeconds: preAlarmSeconds ?? this.preAlarmSeconds,
        sosCancelSeconds: sosCancelSeconds ?? this.sosCancelSeconds,
        sensitivity: sensitivity ?? this.sensitivity,
        sleepEnabled: sleepEnabled ?? this.sleepEnabled,
        sleepScheduleEnabled: sleepScheduleEnabled ?? this.sleepScheduleEnabled,
        sleepStart: sleepStart ?? this.sleepStart,
        sleepEnd: sleepEnd ?? this.sleepEnd,
        sleepMinutes: sleepMinutes ?? this.sleepMinutes,
        smsMode: smsMode ?? this.smsMode,
        smsFallbackSeconds: smsFallbackSeconds ?? this.smsFallbackSeconds,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        lastTelegramCheckAt: lastTelegramCheckAt ?? this.lastTelegramCheckAt,
        lastTelegramCheckOk: lastTelegramCheckOk ?? this.lastTelegramCheckOk,
        savedRingId: clearSavedRingId ? null : savedRingId ?? this.savedRingId,
        firmwareVersion: firmwareVersion ?? this.firmwareVersion,
        simulatedRing: simulatedRing ?? this.simulatedRing,
        simFast: simFast ?? this.simFast,
      );
}

/// `shared_preferences` üzerinde ayar deposu.
class SettingsStore {
  SettingsStore(this._p);
  final SharedPreferences _p;

  static int _clamp(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

  AppSettings load() {
    final checkAt = _p.getString('lastTelegramCheck');
    return AppSettings(
      personName: _p.getString('personName') ?? AppSettings.defaultName,
      welcomeMessage: _p.getString('welcomeMessage') ?? AppSettings.defaultWelcome,
      chatId: _p.getString('chatId') ?? '',
      abruptMinutes: _clamp(_p.getInt('abruptMinutes') ?? 3, 1, 15),
      gradualMinutes: _clamp(_p.getInt('gradualMinutes') ?? 10, 3, 60),
      preAlarmSeconds: _clamp(_p.getInt('preAlarmSeconds') ?? 60, 15, 180),
      sosCancelSeconds: _clamp(_p.getInt('sosCancelSeconds') ?? 15, 5, 30),
      sensitivity: Sensitivity.byName(_p.getString('sensitivity')),
      sleepEnabled: _p.getBool('sleepEnabled') ?? false,
      sleepScheduleEnabled: _p.getBool('sleepScheduleEnabled') ?? false,
      sleepStart: _clamp(_p.getInt('sleepStart') ?? 1410, 0, 1439),
      sleepEnd: _clamp(_p.getInt('sleepEnd') ?? 450, 0, 1439),
      sleepMinutes: _clamp(_p.getInt('sleepMinutes') ?? 30, 10, 90),
      smsMode: SmsMode.byName(_p.getString('smsMode')),
      smsFallbackSeconds: _clamp(_p.getInt('smsFallbackSeconds') ?? 60, 30, 300),
      onboardingDone: _p.getBool('onboardingDone') ?? false,
      lastTelegramCheckAt: checkAt == null ? null : DateTime.tryParse(checkAt),
      lastTelegramCheckOk: _p.getBool('lastTelegramCheckOk'),
      savedRingId: _p.getString('savedRingId'),
      firmwareVersion: _p.getString('firmwareVersion'),
      simulatedRing: _p.getBool('simulatedRing') ?? false,
      simFast: _p.getBool('simFast') ?? false,
    );
  }

  Future<void> save(AppSettings s) async {
    await _p.setString('personName', s.personName);
    await _p.setString('welcomeMessage', s.welcomeMessage);
    await _p.setString('chatId', s.chatId);
    await _p.setInt('abruptMinutes', s.abruptMinutes);
    await _p.setInt('gradualMinutes', s.gradualMinutes);
    await _p.setInt('preAlarmSeconds', s.preAlarmSeconds);
    await _p.setInt('sosCancelSeconds', s.sosCancelSeconds);
    await _p.setString('sensitivity', s.sensitivity.name);
    await _p.setBool('sleepEnabled', s.sleepEnabled);
    await _p.setBool('sleepScheduleEnabled', s.sleepScheduleEnabled);
    await _p.setInt('sleepStart', s.sleepStart);
    await _p.setInt('sleepEnd', s.sleepEnd);
    await _p.setInt('sleepMinutes', s.sleepMinutes);
    await _p.setString('smsMode', s.smsMode.name);
    await _p.setInt('smsFallbackSeconds', s.smsFallbackSeconds);
    await _p.setBool('onboardingDone', s.onboardingDone);
    final at = s.lastTelegramCheckAt;
    if (at != null) await _p.setString('lastTelegramCheck', at.toIso8601String());
    final ok = s.lastTelegramCheckOk;
    if (ok != null) await _p.setBool('lastTelegramCheckOk', ok);
    final ring = s.savedRingId;
    if (ring == null) {
      await _p.remove('savedRingId');
    } else {
      await _p.setString('savedRingId', ring);
    }
    final fw = s.firmwareVersion;
    if (fw != null) await _p.setString('firmwareVersion', fw);
    await _p.setBool('simulatedRing', s.simulatedRing);
    await _p.setBool('simFast', s.simFast);
  }
}

/// Main içinde gerçek değerle değiştirilir.
final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final settingsStoreProvider = Provider<SettingsStore>((ref) => SettingsStore(ref.watch(sharedPrefsProvider)));

/// Ayarların Riverpod deposu.
class SettingsRepository extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsStoreProvider).load();

  /// Ayarı günceller ve kalıcı hâle getirir.
  Future<void> update(AppSettings Function(AppSettings s) change) async {
    final next = change(state);
    state = next;
    await ref.read(settingsStoreProvider).save(next);
  }
}

final settingsProvider = NotifierProvider<SettingsRepository, AppSettings>(SettingsRepository.new);
