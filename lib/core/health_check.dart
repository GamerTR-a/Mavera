/// Kalkan seviyesi.
enum ShieldLevel { protected, attention, unprotected }

/// Sorunun çözümü için kullanıcının yönlendirileceği yer.
enum HealthAction {
  none,
  systemSettings,
  bluetoothSettings,
  ringHelp,
  telegramSettings,
  restartService,
  onboarding,
  backgroundSetup,
  locationSettings,
  contacts,
  resume,
}

/// Tek bir sağlık sorunu.
class HealthIssue {
  const HealthIssue(this.level, this.title, {this.action = HealthAction.none, this.actionLabel});
  final ShieldLevel level;
  final String title;
  final HealthAction action;
  final String? actionLabel;
}

/// Bluetooth adaptör durumu (saf Dart karşılığı).
enum BtStatus { on, off, unauthorized, unknown }

/// Kalkanı belirleyen girdiler.
class HealthInputs {
  const HealthInputs({
    required this.now,
    required this.isAndroid,
    required this.bluetooth,
    required this.lastLineAt,
    required this.notificationsGranted,
    required this.telegramConfigured,
    required this.telegramLastCheckOk,
    required this.foregroundServiceRunning,
    required this.onboardingDone,
    required this.batteryOptimizationExempt,
    required this.fullScreenAllowed,
    required this.locationAlways,
    required this.locationPrecise,
    required this.ringBattery,
    required this.phoneBattery,
    required this.phoneCharging,
    required this.contactsCount,
    required this.pausedUntil,
  });

  final DateTime now;
  final bool isAndroid;
  final BtStatus bluetooth;
  final DateTime? lastLineAt;
  final bool notificationsGranted;
  final bool telegramConfigured;

  /// Son `getMe` kontrolü; hiç yapılmadıysa `null`.
  final bool? telegramLastCheckOk;
  final bool foregroundServiceRunning;
  final bool onboardingDone;
  final bool batteryOptimizationExempt;

  /// Android 14+ tam ekran bildirim izni; bilinmiyorsa/gereksizse `true`.
  final bool fullScreenAllowed;

  /// Alarm anında konum alınabilir mi: iOS'ta "Her Zaman", Android'de "kullanılırken" yeterli.
  final bool locationAlways;
  final bool locationPrecise;
  final int? ringBattery;
  final int? phoneBattery;
  final bool phoneCharging;
  final int contactsCount;
  final DateTime? pausedUntil;
}

/// HealthCheck kuralları (Bölüm 12). Saf Dart.
class HealthCheck {
  ShieldLevel level = ShieldLevel.unprotected;
  List<HealthIssue> issues = const [];

  static const _staleSignal = Duration(seconds: 90);

  void evaluate(HealthInputs i) {
    final list = <HealthIssue>[];
    const u = ShieldLevel.unprotected;
    const a = ShieldLevel.attention;

    if (!i.onboardingDone) {
      list.add(const HealthIssue(u, 'Kurulum bitmedi',
          action: HealthAction.onboarding, actionLabel: 'Kuruluma dön'));
    }
    if (i.bluetooth == BtStatus.off) {
      list.add(const HealthIssue(u, 'Bluetooth kapalı',
          action: HealthAction.bluetoothSettings, actionLabel: 'Ayarları aç'));
    } else if (i.bluetooth == BtStatus.unauthorized) {
      list.add(const HealthIssue(u, 'Bluetooth izni yok',
          action: HealthAction.systemSettings, actionLabel: 'Ayarları aç'));
    }
    final last = i.lastLineAt;
    if (i.bluetooth == BtStatus.on && (last == null || i.now.difference(last) > _staleSignal)) {
      list.add(const HealthIssue(u, 'Yüzük bağlı değil',
          action: HealthAction.ringHelp, actionLabel: 'Yüzük yakında ve şarjlı mı?'));
    }
    if (!i.notificationsGranted) {
      list.add(const HealthIssue(u, 'Bildirimler kapalı, uyarıyı duyamazsın',
          action: HealthAction.systemSettings, actionLabel: 'Ayarları aç'));
    }
    if (!i.telegramConfigured || i.telegramLastCheckOk == false) {
      list.add(const HealthIssue(u, "Telegram'a ulaşılamıyor",
          action: HealthAction.telegramSettings, actionLabel: 'Yakınlar ve Telegram'));
    }
    if (i.isAndroid && i.onboardingDone && !i.foregroundServiceRunning) {
      list.add(const HealthIssue(u, 'Koruma arka planda çalışmıyor',
          action: HealthAction.restartService, actionLabel: 'Yeniden başlat'));
    }
    if (i.isAndroid && !i.batteryOptimizationExempt) {
      list.add(const HealthIssue(a, 'Pil tasarrufu korumayı kapatabilir',
          action: HealthAction.backgroundSetup, actionLabel: 'Düzelt'));
    }
    if (i.isAndroid && !i.fullScreenAllowed) {
      list.add(const HealthIssue(a, 'Kilit ekranında uyarı kapalı',
          action: HealthAction.systemSettings, actionLabel: 'Ayarları aç'));
    }
    if (!i.locationAlways || !i.locationPrecise) {
      list.add(const HealthIssue(a, 'Konum izni eksik',
          action: HealthAction.locationSettings, actionLabel: 'Ayarları aç'));
    }
    final rb = i.ringBattery;
    if (rb != null && rb < 20) {
      list.add(HealthIssue(a, 'Yüzük pili %$rb'));
    }
    final pb = i.phoneBattery;
    if (pb != null && pb < 10 && !i.phoneCharging) {
      list.add(const HealthIssue(a, 'Telefonunun pili azaldı'));
    }
    if (i.contactsCount == 0) {
      list.add(const HealthIssue(a, 'Aranacak kişi eklenmemiş',
          action: HealthAction.contacts, actionLabel: 'Kişiler'));
    }
    final pu = i.pausedUntil;
    if (pu != null && pu.isAfter(i.now)) {
      final mins = (pu.difference(i.now).inSeconds / 60).ceil();
      list.add(HealthIssue(a, 'Koruma $mins dk duraklatıldı',
          action: HealthAction.resume, actionLabel: 'Devam et'));
    }

    // Sıralama: önce kırmızı, sonra turuncu; tablo sırası korunur.
    final sorted = [
      ...list.where((e) => e.level == u),
      ...list.where((e) => e.level == a),
    ];
    issues = sorted;
    level = sorted.isEmpty ? ShieldLevel.protected : sorted.first.level;
  }
}
