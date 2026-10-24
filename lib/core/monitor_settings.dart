/// Hareket hassasiyeti.
enum Sensitivity {
  low,
  medium,
  high;

  static Sensitivity byName(String? n) =>
      values.firstWhere((v) => v.name == n, orElse: () => Sensitivity.medium);
}

/// Monitor'ün her kararda okuduğu ayar anlık görüntüsü (saf Dart).
class MonitorSettings {
  const MonitorSettings({
    this.abruptMinutes = 3,
    this.gradualMinutes = 10,
    this.preAlarmSeconds = 60,
    this.sosCancelSeconds = 15,
    this.minMoves = 3,
    this.sleepEnabled = false,
    this.sleepScheduleEnabled = false,
    this.sleepStart = 1410,
    this.sleepEnd = 450,
    this.sleepMinutes = 30,
    this.armed = true,
    this.timeScale = 1,
  });

  final int abruptMinutes;
  final int gradualMinutes;
  final int preAlarmSeconds;
  final int sosCancelSeconds;
  final int minMoves;
  final bool sleepEnabled;
  final bool sleepScheduleEnabled;
  final int sleepStart;
  final int sleepEnd;
  final int sleepMinutes;

  /// Kurulum bitmeden koruma kapalıdır: hareket izlenir ama alarm üretilmez.
  final bool armed;

  /// Simülasyon "zamanı hızlandır": süre limitleri bu sayıya bölünür.
  final int timeScale;
}
