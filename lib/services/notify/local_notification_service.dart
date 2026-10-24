import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart' show FlutterForegroundTask;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/alarm_reason.dart';
import '../../core/constants.dart';
import '../../core/events.dart';
import '../../data/app_logger.dart';
import 'notification_service.dart';

/// Apple "Critical Alerts" yetkisi onaylanınca `true` yapılır
/// (entitlement: com.apple.developer.usernotifications.critical-alerts).
const bool kCriticalAlertsEntitled = false;

const _pendingActionKey = 'pendingNotificationAction';

/// Arka plan isolate'inden gelen bildirim eylemini ana isolate'e iletir.
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) {
  final action = response.actionId ?? NotificationActions.open;
  final port = IsolateNameServer.lookupPortByName(Channels.notificationPort);
  if (port != null) {
    port.send(action);
    return;
  }
  // Ana isolate yoksa eylem bir sonraki açılışta işlenir.
  unawaited(SharedPreferences.getInstance().then((p) => p.setString(_pendingActionKey, action)));
}

/// `flutter_local_notifications` tabanlı bildirim servisi.
class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  ReceivePort? _port;

  static const _preAlarmId = 1;
  static const _iosPreBase = 1000;
  static const _iosPreFinal = 1099;

  static const chProtection = 'protection';
  static const chPreAlarm = 'prealarm';
  static const chAlarm = 'alarm';
  static const chRing = 'ring';

  static const _icon = 'ic_stat_ring';

  @override
  Future<void> init(void Function(String actionId) onAction) async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Object catch (e) {
      AppLogger.w('Saat dilimi alınamadı: $e');
    }

    final darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      requestCriticalPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'PREALARM',
          actions: [
            DarwinNotificationAction.plain(NotificationActions.imFine, 'İyiyim, iptal et'),
            DarwinNotificationAction.plain(
              NotificationActions.sendNow,
              'Hemen haber ver',
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
          options: {DarwinNotificationCategoryOption.customDismissAction},
        ),
      ],
    );
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings(_icon),
        iOS: darwin,
      ),
      onDidReceiveNotificationResponse: (r) => onAction(r.actionId ?? NotificationActions.open),
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );

    // Arka plan isolate'inden gelen eylemler.
    IsolateNameServer.removePortNameMapping(Channels.notificationPort);
    final port = ReceivePort();
    _port = port;
    IsolateNameServer.registerPortWithName(port.sendPort, Channels.notificationPort);
    port.listen((m) {
      if (m is String) onAction(m);
    });

    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString(_pendingActionKey);
    if (pending != null) {
      await prefs.remove(_pendingActionKey);
      onAction(pending);
    }
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final resp = launch?.notificationResponse;
    if ((launch?.didNotificationLaunchApp ?? false) && resp?.actionId != null) {
      onAction(resp?.actionId ?? NotificationActions.open);
    }

    if (Platform.isAndroid) await _createChannels();
  }

  Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.createNotificationChannel(const AndroidNotificationChannel(
      chProtection,
      'Koruma durumu',
      description: 'Korumanın açık olduğunu gösteren sabit bildirim',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    ));
    await android.createNotificationChannel(AndroidNotificationChannel(
      chPreAlarm,
      'Acil ön uyarı',
      description: 'Yakınlarına haber verilmeden önce sana sorulan uyarı',
      importance: Importance.max,
      bypassDnd: true,
      sound: const UriAndroidNotificationSound('content://settings/system/alarm_alert'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      vibrationPattern: Int64List.fromList([0, 800, 400, 800, 400, 800]),
      enableLights: true,
      ledColor: const Color(0xFFD93636),
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      chAlarm,
      'Alarm durumu',
      description: 'Haber verildi / gönderilemedi bildirimleri',
      importance: Importance.high,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      chRing,
      'Yüzük',
      description: 'Bağlantı ve pil bildirimleri',
      importance: Importance.defaultImportance,
    ));
  }

  DarwinNotificationDetails _darwin(InterruptionLevel level, {String? category, bool sound = true}) =>
      DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: sound,
        interruptionLevel: level,
        categoryIdentifier: category,
      );

  @override
  Future<void> schedulePreAlarm(
    AlarmReason r,
    DateTime deadline, {
    bool rehearsal = false,
    bool motionSeen = false,
  }) async {
    final now = clock.now();
    final remaining = deadline.difference(now).inSeconds.clamp(0, 999);
    final prefix = rehearsal ? 'PROVA · ' : '';
    final title = '$prefix${PreAlarmTexts.title(r)}';
    String body(int rem) {
      final hint = motionSeen ? " Hareket algılandı, iyiysen İyiyim'e bas." : '';
      return '${PreAlarmTexts.body(r, rem)}$hint';
    }

    try {
      if (Platform.isAndroid) {
        final details = AndroidNotificationDetails(
          chPreAlarm,
          'Acil ön uyarı',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          ongoing: true,
          autoCancel: false,
          visibility: NotificationVisibility.public,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          color: const Color(0xFFD93636),
          styleInformation: BigTextStyleInformation(body(remaining)),
          actions: rehearsal
              ? null
              : const [
                  AndroidNotificationAction(
                    NotificationActions.imFine,
                    'İyiyim, iptal et',
                    showsUserInterface: false,
                    cancelNotification: true,
                  ),
                  AndroidNotificationAction(
                    NotificationActions.sendNow,
                    'Hemen haber ver',
                    showsUserInterface: false,
                    cancelNotification: true,
                  ),
                ],
        );
        await _plugin.show(
          id: _preAlarmId,
          title: title,
          body: body(remaining),
          notificationDetails: NotificationDetails(android: details),
        );
        return;
      }

      // iOS: arka planda zamanlayıcı yok; geri sayım zamanlanmış bildirimlerle yürür.
      await _cancelIosPre();
      const level = kCriticalAlertsEntitled ? InterruptionLevel.critical : InterruptionLevel.timeSensitive;
      final d = NotificationDetails(iOS: _darwin(level, category: rehearsal ? null : 'PREALARM'));
      var i = 0;
      for (var t = now; t.isBefore(deadline) && i < K.iosPreAlarmMaxScheduled; i++) {
        final rem = deadline.difference(t).inSeconds;
        if (i == 0) {
          await _plugin.show(id: _iosPreBase, title: title, body: body(rem), notificationDetails: d);
        } else {
          await _plugin.zonedSchedule(
            id: _iosPreBase + i,
            scheduledDate: tz.TZDateTime.from(t, tz.local),
            notificationDetails: d,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            title: title,
            body: body(rem),
          );
        }
        t = t.add(K.preAlarmRepeat);
      }
      if (deadline.isAfter(now)) {
        await _plugin.zonedSchedule(
          id: _iosPreFinal,
          scheduledDate: tz.TZDateTime.from(deadline, tz.local),
          notificationDetails: d,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: title,
          body: rehearsal ? 'Prova bitti.' : 'Yakınlarına haber veriliyor.',
        );
      }
    } on Object catch (e) {
      AppLogger.e('Ön uyarı bildirimi gösterilemedi', e);
    }
  }

  Future<void> _cancelIosPre() async {
    for (var i = 0; i < K.iosPreAlarmMaxScheduled; i++) {
      await _plugin.cancel(id: _iosPreBase + i);
    }
    await _plugin.cancel(id: _iosPreFinal);
  }

  @override
  Future<void> cancelPreAlarm() async {
    try {
      await _plugin.cancel(id: _preAlarmId);
      if (Platform.isIOS) await _cancelIosPre();
    } on Object catch (e) {
      AppLogger.w('Ön uyarı iptal edilemedi: $e');
    }
  }

  @override
  Future<void> show(AppNotification n) async {
    final (channel, channelName, level) = switch (n.kind) {
      AppNotificationKind.delivered ||
      AppNotificationKind.failed ||
      AppNotificationKind.protectionStopped =>
        (chAlarm, 'Alarm durumu', InterruptionLevel.timeSensitive),
      AppNotificationKind.smsSent => (chAlarm, 'Alarm durumu', InterruptionLevel.active),
      AppNotificationKind.disconnected => (chRing, 'Yüzük', InterruptionLevel.timeSensitive),
      AppNotificationKind.lowBattery => (chRing, 'Yüzük', InterruptionLevel.active),
      AppNotificationKind.protectionBack => (chRing, 'Yüzük', InterruptionLevel.passive),
    };
    try {
      await _plugin.show(
        id: n.kind.id,
        title: n.title,
        body: n.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel,
            channelName,
            importance: channel == chAlarm ? Importance.high : Importance.defaultImportance,
            priority: channel == chAlarm ? Priority.high : Priority.defaultPriority,
            styleInformation: BigTextStyleInformation(n.body),
          ),
          iOS: _darwin(level, sound: level != InterruptionLevel.passive),
        ),
      );
    } on Object catch (e) {
      AppLogger.w('Bildirim gösterilemedi: $e');
    }
  }

  @override
  Future<void> cancel(AppNotification n) async {
    try {
      await _plugin.cancel(id: n.kind.id);
    } on Object catch (e) {
      AppLogger.w('Bildirim iptal edilemedi: $e');
    }
  }

  @override
  Future<void> updateOngoing(String text) async {
    if (!Platform.isAndroid) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(notificationTitle: 'Güven Yüzüğü', notificationText: text);
      }
    } on Object catch (e) {
      AppLogger.w('Sabit bildirim güncellenemedi: $e');
    }
  }

  /// AppDelegate bildirimi "302" kimliğiyle zamanlar; FLN iOS'ta kimliği metin olarak kullanır.
  @override
  Future<void> cancelProtectionStopped() =>
      cancel(const AppNotification.ref(AppNotificationKind.protectionStopped));

  @override
  Future<bool> notificationsGranted() async {
    try {
      return await Permission.notification.isGranted;
    } on Object catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final ok = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: kCriticalAlertsEntitled,
      );
      return ok ?? false;
    }
    final s = await Permission.notification.request();
    return s.isGranted;
  }

  /// Android 14+ tam ekran bildirim izni ekranını açar.
  Future<void> requestFullScreenIntent() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestFullScreenIntentPermission();
  }

  /// Rahatsız Etmeyin erişimi.
  Future<bool> hasDndAccess() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.hasNotificationPolicyAccess() ?? false;
  }

  Future<void> requestDndAccess() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationPolicyAccess();
  }

  void dispose() {
    _port?.close();
    IsolateNameServer.removePortNameMapping(Channels.notificationPort);
  }
}
