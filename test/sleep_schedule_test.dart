import 'package:flutter_test/flutter_test.dart';
import 'package:mavera/core/health_check.dart';
import 'package:mavera/core/monitor_settings.dart';
import 'package:mavera/core/sleep_schedule.dart';

void main() {
  test('gece yarısını geçen aralık', () {
    expect(SleepSchedule.inWindow(1410, 450, 1430), isTrue);
    expect(SleepSchedule.inWindow(1410, 450, 0), isTrue);
    expect(SleepSchedule.inWindow(1410, 450, 449), isTrue);
    expect(SleepSchedule.inWindow(1410, 450, 450), isFalse);
    expect(SleepSchedule.inWindow(1410, 450, 1409), isFalse);
  });

  test('aynı gün içindeki aralık', () {
    expect(SleepSchedule.inWindow(780, 900, 800), isTrue);
    expect(SleepSchedule.inWindow(780, 900, 900), isFalse);
    expect(SleepSchedule.inWindow(600, 600, 600), isFalse);
  });

  test('simülasyon ölçeği limitleri 1/10 yapar', () {
    const s = MonitorSettings(timeScale: 10);
    expect(SleepSchedule.limit(s, DateTime(2026, 1, 1, 12), abrupt: true), const Duration(seconds: 18));
  });

  test('format', () {
    expect(SleepSchedule.format(1410), '23:30');
    expect(SleepSchedule.format(450), '07:30');
  });

  group('HealthCheck', () {
    HealthInputs inputs({
      bool notifications = true,
      int? ringBattery = 80,
      DateTime? lastLine,
      bool locationAlways = true,
    }) {
      final now = DateTime(2026, 1, 1, 12);
      return HealthInputs(
        now: now,
        isAndroid: true,
        bluetooth: BtStatus.on,
        lastLineAt: lastLine ?? now.subtract(const Duration(seconds: 10)),
        notificationsGranted: notifications,
        telegramConfigured: true,
        telegramLastCheckOk: true,
        foregroundServiceRunning: true,
        onboardingDone: true,
        batteryOptimizationExempt: true,
        fullScreenAllowed: true,
        locationAlways: locationAlways,
        locationPrecise: true,
        ringBattery: ringBattery,
        phoneBattery: 80,
        phoneCharging: false,
        contactsCount: 2,
        pausedUntil: null,
      );
    }

    test('her şey yolunda → protected', () {
      final h = HealthCheck()..evaluate(inputs());
      expect(h.level, ShieldLevel.protected);
      expect(h.issues, isEmpty);
    });

    test('düşük pil → attention', () {
      final h = HealthCheck()..evaluate(inputs(ringBattery: 15));
      expect(h.level, ShieldLevel.attention);
      expect(h.issues.first.title, 'Yüzük pili %15');
    });

    test('bildirim kapalı + konum eksik → unprotected ve kırmızı önce', () {
      final h = HealthCheck()..evaluate(inputs(notifications: false, locationAlways: false));
      expect(h.level, ShieldLevel.unprotected);
      expect(h.issues.first.title, 'Bildirimler kapalı, uyarıyı duyamazsın');
      expect(h.issues.last.title, 'Konum izni eksik');
    });

    test('90 sn sinyal yok → yüzük bağlı değil', () {
      final h = HealthCheck()..evaluate(inputs(lastLine: DateTime(2026, 1, 1, 11, 58)));
      expect(h.issues.first.title, 'Yüzük bağlı değil');
    });
  });
}
