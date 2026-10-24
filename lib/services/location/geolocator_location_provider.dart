import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../core/models.dart';
import '../../data/app_logger.dart';
import 'location_provider.dart';

/// `geolocator` tabanlı konum sağlayıcı.
class GeolocatorLocationProvider implements LocationProvider {
  static Coord _toCoord(Position p) => Coord(p.latitude, p.longitude, accuracy: p.accuracy, at: p.timestamp);

  @override
  Future<LocationAuth> status() async {
    try {
      final p = await Geolocator.checkPermission();
      return switch (p) {
        LocationPermission.always => LocationAuth.always,
        LocationPermission.whileInUse => LocationAuth.whileInUse,
        _ => LocationAuth.denied,
      };
    } on Object catch (e) {
      AppLogger.w('Konum izni okunamadı: $e');
      return LocationAuth.denied;
    }
  }

  @override
  Future<bool> precise() async {
    try {
      final a = await Geolocator.getLocationAccuracy();
      return a == LocationAccuracyStatus.precise;
    } on Object catch (_) {
      return true;
    }
  }

  @override
  Future<void> request() async {
    var s = await status();
    if (s == LocationAuth.denied) {
      await ph.Permission.locationWhenInUse.request();
      s = await status();
    }
    // Android'de "kullanılırken" yeterli: arka plan erişimi "location" tipli ön plan servisiyle.
    if (s == LocationAuth.whileInUse && Platform.isIOS) {
      await ph.Permission.locationAlways.request();
    }
  }

  LocationSettings _settings({required bool stream}) {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: stream ? 10 : 0,
        intervalDuration: stream ? const Duration(seconds: 30) : null,
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: stream ? 10 : 0,
        allowBackgroundLocationUpdates: stream,
        showBackgroundLocationIndicator: stream,
        pauseLocationUpdatesAutomatically: false,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high);
  }

  @override
  Future<Coord?> current({Duration timeout = const Duration(seconds: 8)}) async {
    if (await status() == LocationAuth.denied) return null;
    try {
      final p = await Geolocator.getCurrentPosition(locationSettings: _settings(stream: false))
          .timeout(timeout);
      return _toCoord(p);
    } on Object catch (e) {
      AppLogger.w('Anlık konum alınamadı, son bilinen deneniyor: ${e.runtimeType}');
      try {
        final last = await Geolocator.getLastKnownPosition();
        return last == null ? null : _toCoord(last);
      } on Object catch (_) {
        return null;
      }
    }
  }

  @override
  Stream<Coord> live() =>
      Geolocator.getPositionStream(locationSettings: _settings(stream: true)).map(_toCoord);
}
