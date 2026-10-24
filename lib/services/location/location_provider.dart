import '../../core/models.dart';

/// Konum izni seviyesi.
enum LocationAuth { denied, whileInUse, always }

/// Konum soyutlaması. Sürekli takip yoktur; akış yalnızca alarm açıkken dinlenir.
abstract class LocationProvider {
  Future<LocationAuth> status();

  /// Hassas konum açık mı (Android 12+ / iOS 14+ yaklaşık konum seçeneği).
  Future<bool> precise();

  /// Önce "kullanılırken", iOS'ta ardından "her zaman" ister.
  Future<void> request();
  Future<Coord?> current({Duration timeout = const Duration(seconds: 8)});
  Stream<Coord> live();
}
