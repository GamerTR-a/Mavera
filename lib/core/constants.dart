/// Uygulama genelindeki eşik, süre ve kimlik sabitleri.
///
/// Kullanıcının değiştirebildiği değerler burada değil, `SettingsRepository`
/// içindedir; burada yalnızca sistemin sabit kuralları durur.
abstract final class K {
  // ---- Bluetooth
  static const ringName = 'GuvenYuzuk';
  static const nusService = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  static const nusTx = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';
  static const nusRx = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E';
  static const lineBufferMaxBytes = 256;
  static const desiredMtu = 247;
  static const reconnectDelay = Duration(seconds: 5);
  static const rssiInterval = Duration(seconds: 15);
  static const scanWindow = Duration(seconds: 20);
  static const scanPause = Duration(seconds: 10);

  // ---- Hareket algılama
  static const heartbeatInterval = Duration(seconds: 30);
  static const activeMoves = 50;
  static const abruptLookback = 6;
  static const abruptMinActive = 3;
  static const recentMovesCount = 40;
  static const snapshotCount = 30;
  static const minMovesLow = 6;
  static const minMovesMedium = 3;
  static const minMovesHigh = 1;
  static const pauseMinBeforeAutoResume = Duration(minutes: 5);
  static const staleSignal = Duration(seconds: 90);
  static const disconnectNotifyDelay = Duration(seconds: 180);
  static const sosDedupWindow = Duration(seconds: 60);
  static const iosPreAlarmSlack = Duration(seconds: 30);

  // ---- Pil
  static const ringBatteryNoBatteryMv = 2500;
  static const ringBatteryWarn1 = 20;
  static const ringBatteryWarn2 = 10;
  static const ringBatteryReset = 40;
  static const ringBatteryFullPct = 95;
  static const phoneBatteryLow = 10;
  static const batteryHistoryWindow = Duration(hours: 24);
  static const batteryMinHistory = Duration(hours: 2);

  // ---- Gönderim
  static const locationTimeout = Duration(seconds: 8);
  static const telegramTimeout = Duration(seconds: 10);
  static const retryInterval = Duration(seconds: 30);
  static const failNotifyAfter = Duration(minutes: 2);
  static const lateNoteThreshold = Duration(minutes: 1);
  static const livePeriodSeconds = 3600;
  static const liveEditInterval = Duration(seconds: 60);
  static const maxHorizontalAccuracy = 1500.0;
  static const telegramCheckEvery = Duration(hours: 24);

  // ---- Bildirim
  static const preAlarmRepeat = Duration(seconds: 10);
  static const iosPreAlarmMaxScheduled = 30;
  static const rehearsalSeconds = 15;

  // ---- Kayıt
  static const eventRetention = Duration(days: 30);
  static const logRingLines = 2000;
  static const logShareLines = 500;
  static const welcomeMaxLength = 200;

  // ---- Ön uyarı iptal önerisi
  static const cancelSuggestThreshold = 5;

  // ---- Ekran
  static const helpHoldDuration = Duration(seconds: 2);
}

/// Platform kanalı adları; Kotlin ve Swift tarafı da aynı adları kullanır.
abstract final class Channels {
  static const sms = 'guvenyuzuk/sms';
  static const backgroundTask = 'guvenyuzuk/background_task';
  static const system = 'guvenyuzuk/system';
  static const notificationPort = 'guvenyuzuk/notification_actions';
}
