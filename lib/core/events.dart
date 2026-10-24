/// Geçmişe yazılan olay türleri (sqflite `events.kind`).
enum EventKind {
  preAlarmCancelled,
  preAlarmEscalated,
  alarmSent,
  alarmDeliveredLate,
  smsSent,
  alarmClosed,
  sos,
  tremor,
  manualHelp,
  ringConnected,
  ringDisconnected,
  lowBattery,
  paused,
  resumed,
  sleepOn,
  sleepOff,
  packetLoss,
  telegramCheckFailed,
  protectionGap;

  static EventKind? byName(String name) {
    for (final k in values) {
      if (k.name == name) return k;
    }
    return null;
  }
}

/// Monitor ve gönderici tarafından istenen kullanıcı bildirimleri.
enum AppNotificationKind {
  delivered(101),
  failed(102),
  smsSent(103),
  disconnected(201),
  lowBattery(202),
  protectionBack(301),
  protectionStopped(302);

  const AppNotificationKind(this.id);
  final int id;
}

/// Gösterilecek bildirim; metinler saf Dart çekirdekte üretilir.
class AppNotification {
  const AppNotification(this.kind, {required this.title, required this.body});
  final AppNotificationKind kind;
  final String title;
  final String body;

  /// İptal amaçlı (metinsiz) referans.
  const AppNotification.ref(this.kind)
      : title = '',
        body = '';
}
