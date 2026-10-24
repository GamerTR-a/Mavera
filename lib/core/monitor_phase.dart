import 'alarm_reason.dart';
import 'alarm_record.dart';

/// Monitor durum makinesinin anlık fazı.
sealed class MonitorPhase {
  const MonitorPhase();
}

/// Koruma kullanıcı tarafından duraklatıldı.
class Paused extends MonitorPhase {
  const Paused({required this.until, required this.since});
  final DateTime until;
  final DateTime since;
}

/// Hareket izleniyor, sorun yok.
class Watching extends MonitorPhase {
  const Watching();
}

/// Hareketsizlik sayılıyor.
class Counting extends MonitorPhase {
  const Counting({required this.since, required this.abrupt});
  final DateTime since;
  final bool abrupt;
}

/// Meryem'e soruluyor; [deadline]'a kadar iptal edilmezse alarm gider.
class PreAlarm extends MonitorPhase {
  const PreAlarm({
    required this.reason,
    required this.deadline,
    required this.startedAt,
    this.motionSeen = false,
  });
  final AlarmReason reason;
  final DateTime deadline;
  final DateTime startedAt;

  /// Ön uyarı sırasında hareket algılandı (ipucu gösterilir, iptal edilmez).
  final bool motionSeen;

  PreAlarm copyWith({DateTime? deadline, bool? motionSeen}) => PreAlarm(
        reason: reason,
        deadline: deadline ?? this.deadline,
        startedAt: startedAt,
        motionSeen: motionSeen ?? this.motionSeen,
      );
}

/// Alarm gönderildi / gönderiliyor.
class AlarmActive extends MonitorPhase {
  const AlarmActive(this.record);
  final AlarmRecord record;
}
