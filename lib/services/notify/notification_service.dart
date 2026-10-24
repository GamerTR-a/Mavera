import '../../core/alarm_reason.dart';
import '../../core/events.dart';

/// Bildirim eylem kimlikleri.
abstract final class NotificationActions {
  static const imFine = 'IM_FINE';
  static const sendNow = 'SEND_NOW';
  static const open = 'OPEN';
}

/// Yerel bildirim soyutlaması.
abstract class NotificationService {
  Future<void> init(void Function(String actionId) onAction);

  /// Ön uyarı bildirimini gösterir / zamanlar. [rehearsal] ise "PROVA" etiketlidir.
  Future<void> schedulePreAlarm(AlarmReason r, DateTime deadline, {bool rehearsal = false, bool motionSeen = false});
  Future<void> cancelPreAlarm();
  Future<void> show(AppNotification n);
  Future<void> cancel(AppNotification n);

  /// Android ön plan servisinin sabit bildirim metni.
  Future<void> updateOngoing(String text);

  /// iOS'ta AppDelegate'in zamanladığı "Koruma durdu" bildirimini kaldırır.
  Future<void> cancelProtectionStopped();

  Future<bool> notificationsGranted();
  Future<bool> requestPermission();
}

/// Ön uyarı bildirim metinleri.
abstract final class PreAlarmTexts {
  static String title(AlarmReason r) => switch (r) {
        Sos() => 'Yardım isteğin alındı',
        Tremor() => 'Titreme algılandı',
        Inactivity() => 'Hareketsizlik algılandı',
        Manual() => 'Yardım isteniyor',
      };

  static String reason(AlarmReason r) => switch (r) {
        Inactivity(:final minutes) => '$minutes dakikadır hiç hareket algılanmadı',
        Sos() => 'Yüzüğe üç kez vurdun',
        Tremor() => 'Uzun süreli titreme algılandı',
        Manual() => 'Uygulamadan yardım istedin',
      };

  static String body(AlarmReason r, int remaining) =>
      "${reason(r)}. İyiysen İyiyim'e bas. $remaining sn içinde yakınlarına haber verilecek.";
}
