import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/app_logger.dart';
import 'background_host.dart';

/// Android ön plan servisi.
///
/// KARAR (R1/R2): Çekirdek ana isolate'te kalır. Ana Flutter motoru
/// `MaveraApplication` içinde oluşturulup önbelleğe alınır ve aktiviteyle
/// birlikte yok edilmez; ön plan servisi süreci canlı tuttuğu sürece
/// (uygulama son uygulamalardan kaydırılsa bile) Dart çekirdeği çalışır.
/// Açılışta `RebootReceiver` süreci başlatır → `Application.onCreate` motoru
/// ve `main()`'i çalıştırır → çekirdek ekransız başlar. Bu yüzden servis bir
/// `TaskHandler` isolate'i başlatmaz (callback yok).
class AndroidForegroundHost implements BackgroundHost {
  AndroidForegroundHost() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'protection',
        channelName: 'Koruma durumu',
        channelDescription: 'Korumanın açık olduğunu gösteren sabit bildirim',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: false),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
        allowAutoRestart: true,
        stopWithTask: false,
      ),
    );
  }

  @override
  bool get timersRunInBackground => true;

  /// Çalışan servis "location" tipini taşıyor mu.
  bool _withLocation = false;

  /// KARAR: "location" tipi yalnızca uygulama ön plandayken ve "kullanılırken"
  /// konum izni varken eklenir. Arka plan konum izni olmadan Android 14+ bu tipi
  /// arka planda (ör. açılışta) başlatmaya izin vermez; o durumda servis yalnızca
  /// "connectedDevice" ile açılır, uygulama ilk kez ön plana gelince yükseltilir.
  Future<List<ForegroundServiceTypes>> _types({required bool foreground}) async {
    final types = <ForegroundServiceTypes>[ForegroundServiceTypes.connectedDevice];
    if (foreground && await Permission.locationWhenInUse.isGranted) {
      types.add(ForegroundServiceTypes.location);
    }
    return types;
  }

  @override
  Future<void> start(String text, {bool foreground = false}) async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await update(text);
        return;
      }
      final types = await _types(foreground: foreground);
      final r = await FlutterForegroundTask.startService(
        serviceId: 7,
        serviceTypes: types,
        notificationTitle: 'Güven Yüzüğü',
        notificationText: text,
        notificationIcon: const NotificationIcon(metaDataName: 'com.mavera.service.NOTIFICATION_ICON'),
      );
      if (r is ServiceRequestFailure) {
        AppLogger.e('Ön plan servisi başlatılamadı', r.error);
      } else {
        _withLocation = types.contains(ForegroundServiceTypes.location);
        AppLogger.i('Ön plan servisi başladı (konum: $_withLocation)');
      }
    } on Object catch (e) {
      AppLogger.e('Ön plan servisi başlatılamadı', e);
    }
  }

  @override
  Future<void> ensureForegroundCapabilities(String text) async {
    try {
      final running = await FlutterForegroundTask.isRunningService;
      if (running && (_withLocation || !await Permission.locationWhenInUse.isGranted)) return;
      if (running) await FlutterForegroundTask.stopService();
      await start(text, foreground: true);
    } on Object catch (e) {
      AppLogger.e('Ön plan servisi yükseltilemedi', e);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await FlutterForegroundTask.stopService();
      _withLocation = false;
    } on Object catch (e) {
      AppLogger.w('Ön plan servisi durdurulamadı: $e');
    }
  }

  @override
  Future<bool> isRunning() async {
    try {
      return await FlutterForegroundTask.isRunningService;
    } on Object catch (_) {
      return false;
    }
  }

  @override
  Future<void> update(String text) async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(notificationTitle: 'Güven Yüzüğü', notificationText: text);
      }
    } on Object catch (e) {
      AppLogger.w('Servis bildirimi güncellenemedi: $e');
    }
  }
}
