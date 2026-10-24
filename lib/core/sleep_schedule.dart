import 'monitor_settings.dart';

/// Uyku modu kuralları (saf Dart).
abstract final class SleepSchedule {
  /// [minuteOfDay], [start]–[end) aralığında mı? Aralık gece yarısını geçebilir.
  static bool inWindow(int start, int end, int minuteOfDay) {
    if (start == end) return false;
    if (start < end) return minuteOfDay >= start && minuteOfDay < end;
    return minuteOfDay >= start || minuteOfDay < end;
  }

  /// Şu an uyku modunda sayılır mı?
  static bool isAsleep(MonitorSettings s, DateTime now) {
    if (s.sleepEnabled) return true;
    if (!s.sleepScheduleEnabled) return false;
    return inWindow(s.sleepStart, s.sleepEnd, now.hour * 60 + now.minute);
  }

  /// Hareketsizlik süre limiti (dakika, ölçeksiz).
  static int limitMinutes(MonitorSettings s, DateTime now, {required bool abrupt}) {
    final base = abrupt ? s.abruptMinutes : s.gradualMinutes;
    return isAsleep(s, now) ? (base > s.sleepMinutes ? base : s.sleepMinutes) : base;
  }

  /// Hareketsizlik süre limiti; simülasyon ölçeği uygulanmış.
  static Duration limit(MonitorSettings s, DateTime now, {required bool abrupt}) {
    final m = limitMinutes(s, now, abrupt: abrupt);
    final scale = s.timeScale < 1 ? 1 : s.timeScale;
    return Duration(seconds: (m * 60 / scale).round());
  }

  /// "23:30" biçimi.
  static String format(int minuteOfDay) {
    final h = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
    final m = (minuteOfDay % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
