/// Ön uyarının / alarmın nedeni.
sealed class AlarmReason {
  const AlarmReason();

  /// JSON'a yazılan tür adı.
  String get type;

  Map<String, Object?> toJson() => {'type': type};

  static AlarmReason fromJson(Map<String, Object?> json) {
    switch (json['type']) {
      case 'inactivity':
        return Inactivity(
          minutes: (json['minutes'] as num?)?.toInt() ?? 0,
          abrupt: json['abrupt'] == true,
        );
      case 'sos':
        return const Sos();
      case 'tremor':
        return const Tremor();
      case 'manual':
      default:
        return const Manual();
    }
  }
}

/// Hareketsizlik süresi doldu.
class Inactivity extends AlarmReason {
  const Inactivity({required this.minutes, required this.abrupt});

  /// Uygulanan süre limiti (dakika).
  final int minutes;

  /// Hareket aniden mi kesildi.
  final bool abrupt;

  @override
  String get type => 'inactivity';

  @override
  Map<String, Object?> toJson() => {'type': type, 'minutes': minutes, 'abrupt': abrupt};

  @override
  bool operator ==(Object other) =>
      other is Inactivity && other.minutes == minutes && other.abrupt == abrupt;

  @override
  int get hashCode => Object.hash(minutes, abrupt);
}

/// Yüzüğe üç kez vuruldu.
class Sos extends AlarmReason {
  const Sos();
  @override
  String get type => 'sos';
  @override
  bool operator ==(Object other) => other is Sos;
  @override
  int get hashCode => type.hashCode;
}

/// Uzun süreli titreme.
class Tremor extends AlarmReason {
  const Tremor();
  @override
  String get type => 'tremor';
  @override
  bool operator ==(Object other) => other is Tremor;
  @override
  int get hashCode => type.hashCode;
}

/// Meryem uygulamadan yardım istedi.
class Manual extends AlarmReason {
  const Manual();
  @override
  String get type => 'manual';
  @override
  bool operator ==(Object other) => other is Manual;
  @override
  int get hashCode => type.hashCode;
}
