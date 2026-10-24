/// Coğrafi konum.
class Coord {
  const Coord(this.lat, this.lon, {this.accuracy, this.at});
  final double lat;
  final double lon;

  /// Yatay doğruluk (m).
  final double? accuracy;
  final DateTime? at;

  @override
  String toString() => '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
}

/// Alarmda aranacak yakın kişi.
class EmergencyContact {
  const EmergencyContact({this.id, required this.name, required this.phone, this.sortOrder = 0});
  final int? id;
  final String name;
  final String phone;
  final int sortOrder;

  EmergencyContact copyWith({int? id, String? name, String? phone, int? sortOrder}) =>
      EmergencyContact(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}

/// Geçmişteki bir olay.
class EventEntry {
  const EventEntry({
    this.id,
    required this.at,
    required this.kind,
    required this.detail,
    required this.movesSnapshot,
    required this.sentToGroup,
  });
  final int? id;
  final DateTime at;
  final String kind;
  final String detail;
  final List<int> movesSnapshot;
  final bool sentToGroup;
}
