import 'alarm_reason.dart';

/// Tek bir alarmın gönderim kaydı. Her değişimde diske yazılır.
class AlarmRecord {
  AlarmRecord({
    required this.id,
    required this.reason,
    required this.triggeredAt,
    required this.lastMotionAt,
    this.deliveredAt,
    this.attempts = 0,
    this.liveMessageId,
    this.liveUntil,
    this.smsSent = false,
    this.smsAttempted = false,
    this.closedAt,
    this.ringBattery,
    this.preAlarmSeconds,
  });

  final String id;
  final AlarmReason reason;
  final DateTime triggeredAt;
  final DateTime lastMotionAt;
  DateTime? deliveredAt;
  int attempts;
  int? liveMessageId;
  DateTime? liveUntil;
  bool smsSent;

  /// KARAR: SMS yedeğinin "tam bir kez" denenmesi için sonuçtan bağımsız bayrak.
  bool smsAttempted;
  DateTime? closedAt;

  /// Alarm anındaki yüzük pili (mesajda gösterilir).
  final int? ringBattery;

  /// Cevap verilmeyen ön uyarının süresi (sn); elle alarmda `null`.
  final int? preAlarmSeconds;

  bool get delivered => deliveredAt != null;

  Map<String, Object?> toJson() => {
        'id': id,
        'reason': reason.toJson(),
        'triggeredAt': triggeredAt.toIso8601String(),
        'lastMotionAt': lastMotionAt.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'attempts': attempts,
        'liveMessageId': liveMessageId,
        'liveUntil': liveUntil?.toIso8601String(),
        'smsSent': smsSent,
        'smsAttempted': smsAttempted,
        'closedAt': closedAt?.toIso8601String(),
        'ringBattery': ringBattery,
        'preAlarmSeconds': preAlarmSeconds,
      };

  static AlarmRecord fromJson(Map<String, Object?> j) {
    DateTime? d(Object? v) => v is String ? DateTime.tryParse(v) : null;
    final reason = j['reason'];
    return AlarmRecord(
      id: j['id'] as String? ?? '',
      reason: reason is Map<String, Object?> ? AlarmReason.fromJson(reason) : const Manual(),
      triggeredAt: d(j['triggeredAt']) ?? DateTime.now(),
      lastMotionAt: d(j['lastMotionAt']) ?? DateTime.now(),
      deliveredAt: d(j['deliveredAt']),
      attempts: (j['attempts'] as num?)?.toInt() ?? 0,
      liveMessageId: (j['liveMessageId'] as num?)?.toInt(),
      liveUntil: d(j['liveUntil']),
      smsSent: j['smsSent'] == true,
      smsAttempted: j['smsAttempted'] == true,
      closedAt: d(j['closedAt']),
      ringBattery: (j['ringBattery'] as num?)?.toInt(),
      preAlarmSeconds: (j['preAlarmSeconds'] as num?)?.toInt(),
    );
  }
}
