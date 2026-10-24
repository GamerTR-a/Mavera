import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/app_logger.dart';
import 'location/location_provider.dart';
import 'notify/local_notification_service.dart';
import 'notify/notification_service.dart';
import 'system_channel.dart';

/// İzin kartının durumu.
enum PermState { granted, partial, denied }

/// İzinlerin anlık görüntüsü.
class PermissionsSnapshot {
  const PermissionsSnapshot({
    required this.bluetooth,
    required this.notifications,
    required this.location,
    required this.locationPrecise,
    required this.batteryOptimization,
    required this.fullScreen,
    required this.dnd,
    required this.sms,
  });

  final PermState bluetooth;
  final PermState notifications;
  final LocationAuth location;
  final bool locationPrecise;
  final PermState batteryOptimization;
  final PermState fullScreen;
  final PermState dnd;
  final PermState sms;

  /// Android'de "kullanılırken" yeterlidir (konum tipli ön plan servisi); iOS'ta "Her Zaman" gerekir.
  PermState get locationState => switch (location) {
        LocationAuth.always => locationPrecise ? PermState.granted : PermState.partial,
        LocationAuth.whileInUse when Platform.isAndroid =>
          locationPrecise ? PermState.granted : PermState.partial,
        LocationAuth.whileInUse => PermState.partial,
        LocationAuth.denied => PermState.denied,
      };

  /// Kurulum Ekran 3 devam koşulu.
  bool get coreGranted =>
      bluetooth == PermState.granted &&
      notifications == PermState.granted &&
      location != LocationAuth.denied;
}

/// İzinleri sırayla isteyen ve durumlarını okuyan yardımcı (Bölüm 8 sırası).
class PermissionsService {
  PermissionsService(this._location, this._notifications);
  final LocationProvider _location;
  final NotificationService _notifications;

  static PermState _of(PermissionStatus s) =>
      s.isGranted ? PermState.granted : (s.isLimited || s.isProvisional ? PermState.partial : PermState.denied);

  Future<PermState> bluetooth() async {
    if (Platform.isAndroid) {
      final scan = await Permission.bluetoothScan.status;
      final conn = await Permission.bluetoothConnect.status;
      return scan.isGranted && conn.isGranted ? PermState.granted : PermState.denied;
    }
    return _of(await Permission.bluetooth.status);
  }

  Future<PermissionsSnapshot> read() async {
    final android = Platform.isAndroid;
    final loc = await _location.status();
    final precise = loc == LocationAuth.denied ? false : await _location.precise();
    var dnd = PermState.denied;
    final n = _notifications;
    if (android && n is LocalNotificationService) {
      dnd = await n.hasDndAccess() ? PermState.granted : PermState.denied;
    }
    return PermissionsSnapshot(
      bluetooth: await bluetooth(),
      notifications: await _notifications.notificationsGranted() ? PermState.granted : PermState.denied,
      location: loc,
      locationPrecise: precise,
      batteryOptimization:
          !android || await Permission.ignoreBatteryOptimizations.isGranted ? PermState.granted : PermState.denied,
      fullScreen: await SystemChannel.canUseFullScreenIntent() ? PermState.granted : PermState.denied,
      dnd: dnd,
      sms: android && await Permission.sms.isGranted ? PermState.granted : PermState.denied,
    );
  }

  Future<void> requestBluetooth() async {
    try {
      if (Platform.isAndroid) {
        final r = await [Permission.bluetoothScan, Permission.bluetoothConnect].request();
        if (r.values.any((s) => s.isPermanentlyDenied)) await openAppSettings();
      } else {
        final s = await Permission.bluetooth.request();
        if (s.isPermanentlyDenied) await openAppSettings();
      }
    } on Object catch (e) {
      AppLogger.w('Bluetooth izni istenemedi: $e');
    }
  }

  Future<void> requestNotifications() async {
    final ok = await _notifications.requestPermission();
    if (!ok && await Permission.notification.isPermanentlyDenied) await openAppSettings();
  }

  Future<void> requestLocation() async {
    final before = await _location.status();
    await _location.request();
    final after = await _location.status();
    final enough = Platform.isAndroid ? after != LocationAuth.denied : after == LocationAuth.always;
    if (before == after && !enough) await openAppSettings();
  }

  Future<void> requestBatteryOptimization() async {
    await Permission.ignoreBatteryOptimizations.request();
  }

  Future<void> requestFullScreen() async {
    final n = _notifications;
    if (n is LocalNotificationService) await n.requestFullScreenIntent();
  }

  Future<void> requestDnd() async {
    final n = _notifications;
    if (n is LocalNotificationService) await n.requestDndAccess();
  }

  Future<bool> requestSms() async {
    final s = await Permission.sms.request();
    if (s.isPermanentlyDenied) await openAppSettings();
    return s.isGranted;
  }

  /// Telefon üreticisi (pil yönlendirmesi için).
  static Future<String> manufacturer() async {
    if (!Platform.isAndroid) return 'apple';
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.manufacturer.toLowerCase();
    } on Object catch (_) {
      return '';
    }
  }
}
