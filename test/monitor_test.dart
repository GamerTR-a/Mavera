import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavera/core/alarm_reason.dart';
import 'package:mavera/core/events.dart';
import 'package:mavera/core/monitor.dart';
import 'package:mavera/core/monitor_phase.dart';
import 'package:mavera/core/monitor_settings.dart';
import 'package:mavera/core/ring_protocol.dart';
import 'package:mavera/core/sleep_schedule.dart';

import 'fakes.dart';

/// Testleri sahte zamanda çalıştırır.
void run(DateTime start, void Function(FakeAsync async) body) {
  fakeAsync((async) {
    withClock(async.getClock(start), () => body(async));
  });
}

class Harness {
  Harness({MonitorSettings settings = const MonitorSettings()}) : _settings = settings {
    monitor = Monitor(settings: () => _settings, alarms: sink, events: events);
  }

  MonitorSettings _settings;
  set settings(MonitorSettings s) => _settings = s;
  final sink = FakeSink();
  final events = FakeEvents();
  late final Monitor monitor;
  int _seq = 0;

  void hb(int moves) {
    monitor.handle(Heartbeat(seq: _seq, moves: moves, intensity: 0, millivolts: 3900, percent: 80, flags: 0));
    _seq = (_seq + 1) % 256;
  }

  /// [d] boyunca saniyede bir tick (Android modu).
  void advance(FakeAsync async, Duration d) {
    for (var i = 0; i < d.inSeconds; i++) {
      async.elapse(const Duration(seconds: 1));
      monitor.tick();
    }
  }

  /// [count] HB, aralarında 30 sn ve saniyelik tick.
  void signals(FakeAsync async, int moves, int count) {
    for (var i = 0; i < count; i++) {
      hb(moves);
      advance(async, const Duration(seconds: 30));
    }
  }
}

void main() {
  final noon = DateTime(2026, 10, 20, 12);

  test('1. Hareketli sinyaller → ön uyarı yok', () {
    run(noon, (async) {
      final h = Harness()..monitor.ringConnected();
      h.signals(async, 120, 60);
      expect(h.monitor.phase, isA<Watching>());
      expect(h.sink.dispatched, isEmpty);
    });
  });

  test('2. 6 aktif sinyal sonra sıfır → abrupt=true, 3 dk\'da ön uyarı', () {
    run(noon, (async) {
      final h = Harness()..monitor.ringConnected();
      h.signals(async, 120, 6);
      h.hb(0);
      final p = h.monitor.phase;
      expect(p, isA<Counting>());
      expect((p as Counting).abrupt, isTrue);
      // 2:59'da hâlâ sayım.
      for (var i = 0; i < 5; i++) {
        h.advance(async, const Duration(seconds: 30));
        h.hb(0);
      }
      h.advance(async, const Duration(seconds: 29));
      expect(h.monitor.phase, isA<Counting>());
      h.advance(async, const Duration(seconds: 1));
      final pre = h.monitor.phase;
      expect(pre, isA<PreAlarm>());
      expect((pre as PreAlarm).reason, const Inactivity(minutes: 3, abrupt: true));
    });
  });

  test('3. Yavaş azalan sinyaller sonra sıfır → abrupt=false, 10 dk\'da ön uyarı', () {
    run(noon, (async) {
      final h = Harness()..monitor.ringConnected();
      for (final m in [120, 80, 40, 20, 10, 5]) {
        h.hb(m);
        h.advance(async, const Duration(seconds: 30));
      }
      h.hb(0);
      expect((h.monitor.phase as Counting).abrupt, isFalse);
      for (var i = 0; i < 19; i++) {
        h.advance(async, const Duration(seconds: 30));
        h.hb(0);
      }
      h.advance(async, const Duration(seconds: 29));
      expect(h.monitor.phase, isA<Counting>());
      h.advance(async, const Duration(seconds: 1));
      expect(h.monitor.phase, isA<PreAlarm>());
      expect((h.monitor.phase as PreAlarm).reason, const Inactivity(minutes: 10, abrupt: false));
    });
  });

  test('4. Ön uyarıda imFine() → Watching, dispatch çağrılmadı', () {
    run(noon, (async) {
      final h = Harness()..monitor.ringConnected();
      h.hb(120);
      h.monitor.handle(const SosMessage(1));
      expect(h.monitor.phase, isA<PreAlarm>());
      h.monitor.imFine();
      expect(h.monitor.phase, isA<Watching>());
      h.advance(async, const Duration(minutes: 2));
      expect(h.sink.dispatched, isEmpty);
      expect(h.events.logs, contains(EventKind.preAlarmCancelled));
    });
  });

  test('5. Deadline geçti → dispatch tam 1 kez', () {
    run(noon, (async) {
      final h = Harness()..monitor.ringConnected();
      h.hb(120);
      h.monitor.handle(const TremorMessage(4));
      expect(h.monitor.phase, isA<PreAlarm>());
      h.advance(async, const Duration(seconds: 59));
      expect(h.sink.dispatched, isEmpty);
      h.advance(async, const Duration(seconds: 1));
      expect(h.sink.dispatched, hasLength(1));
      h.advance(async, const Duration(minutes: 5));
      expect(h.sink.dispatched, hasLength(1));
      expect(h.monitor.phase, isA<AlarmActive>());
    });
  });

  test('6. Ön uyarıda hareketli HB → ön uyarı sürüyor', () {
    run(noon, (async) {
      final h = Harness()..monitor.ringConnected();
      h.hb(120);
      h.monitor.handle(const TremorMessage(1));
      h.advance(async, const Duration(seconds: 10));
      h.hb(200);
      final p = h.monitor.phase;
      expect(p, isA<PreAlarm>());
      expect((p as PreAlarm).motionSeen, isTrue);
    });
  });

  test('7. SOS → 15 sn\'lik ön uyarı; ön uyarıdayken SOS deadline\'ı kısaltır', () {
    run(noon, (async) {
      final h = Harness()..monitor.ringConnected();
      h.hb(120);
      final t0 = clock.now();
      h.monitor.handle(const SosMessage(1));
      expect((h.monitor.phase as PreAlarm).deadline, t0.add(const Duration(seconds: 15)));

      final h2 = Harness()..monitor.ringConnected();
      h2.hb(120);
      h2.monitor.handle(const TremorMessage(2));
      final longDeadline = (h2.monitor.phase as PreAlarm).deadline;
      h2.advance(async, const Duration(seconds: 5));
      h2.monitor.handle(const SosMessage(3));
      final d = (h2.monitor.phase as PreAlarm).deadline;
      expect(d.isBefore(longDeadline), isTrue);
      expect(d, clock.now().add(const Duration(seconds: 15)));
    });
  });

  test('8. Paused + hareketsizlik → alarm yok; Paused + SOS → ön uyarı', () {
    run(noon, (async) {
      final h = Harness()..monitor.ringConnected();
      h.hb(120);
      h.monitor.pause(const Duration(hours: 1));
      h.signals(async, 0, 40);
      expect(h.monitor.phase, isA<Paused>());
      expect(h.sink.dispatched, isEmpty);
      h.monitor.handle(const SosMessage(9));
      expect(h.monitor.phase, isA<PreAlarm>());
    });
  });

  test('9. Bağlantı kopması → asla alarm; yeniden bağlanınca sayım sıfırdan', () {
    run(noon, (async) {
      final h = Harness()..monitor.ringConnected();
      h.signals(async, 120, 6);
      h.hb(0);
      expect(h.monitor.phase, isA<Counting>());
      h.monitor.ringDisconnected();
      h.advance(async, const Duration(minutes: 30));
      expect(h.sink.dispatched, isEmpty);
      expect(h.monitor.phase, isA<Watching>());
      expect(h.events.notified, contains(AppNotificationKind.disconnected));
      h.monitor.ringConnected();
      expect(h.events.cancelled, contains(AppNotificationKind.disconnected));
      h.hb(0);
      expect(h.monitor.phase, isA<Counting>());
      h.advance(async, const Duration(seconds: 60));
      expect(h.monitor.phase, isA<Counting>());
    });
  });

  test('9b. 90 sn satır gelmezse kopmuş sayılır, gruba alarm gitmez', () {
    run(noon, (async) {
      final h = Harness()..monitor.ringConnected();
      h.hb(120);
      h.advance(async, const Duration(seconds: 91));
      expect(h.monitor.connected, isFalse);
      h.advance(async, const Duration(minutes: 20));
      expect(h.sink.dispatched, isEmpty);
    });
  });

  test('10. Gece yarısını geçen uyku aralığında doğru limit', () {
    const s = MonitorSettings(sleepScheduleEnabled: true, sleepStart: 1410, sleepEnd: 450, sleepMinutes: 30);
    expect(SleepSchedule.limitMinutes(s, DateTime(2026, 1, 1, 0, 30), abrupt: true), 30);
    expect(SleepSchedule.limitMinutes(s, DateTime(2026, 1, 1, 23, 45), abrupt: false), 30);
    expect(SleepSchedule.limitMinutes(s, DateTime(2026, 1, 1, 7, 30), abrupt: true), 3);
    expect(SleepSchedule.limitMinutes(s, DateTime(2026, 1, 1, 12), abrupt: false), 10);
    const s2 = MonitorSettings(sleepEnabled: true, gradualMinutes: 45, sleepMinutes: 30);
    expect(SleepSchedule.limitMinutes(s2, DateTime(2026, 1, 1, 12), abrupt: false), 45);
  });

  test('11. Alarm açıkken SOS → extraSos, yeni alarm yok', () {
    run(noon, (async) {
      final h = Harness()..monitor.ringConnected();
      h.hb(120);
      h.monitor.requestHelp();
      expect(h.sink.dispatched, hasLength(1));
      h.monitor.handle(const SosMessage(5));
      expect(h.sink.extra, 1);
      expect(h.sink.dispatched, hasLength(1));
    });
  });

  test('12. iOS modu: deadline 25 sn önce geçmiş, gelen HB ile alarm gönderilir', () {
    run(noon, (async) {
      final h = Harness()..monitor.ringConnected();
      h.hb(120);
      h.monitor.handle(const SosMessage(1));
      expect(h.monitor.phase, isA<PreAlarm>());
      // iOS arka plan: zamanlayıcı yok, yalnızca zaman akar.
      async.elapse(const Duration(seconds: 15 + 25));
      expect(h.sink.dispatched, isEmpty);
      h.hb(0);
      expect(h.sink.dispatched, hasLength(1));
      expect(h.monitor.phase, isA<AlarmActive>());
    });
  });

  test('Kurulum bitmeden (armed=false) SOS alarm üretmez', () {
    run(noon, (async) {
      final h = Harness(settings: const MonitorSettings(armed: false))..monitor.ringConnected();
      h.hb(120);
      h.monitor.handle(const SosMessage(1));
      expect(h.monitor.phase, isNot(isA<PreAlarm>()));
    });
  });

  test('Aynı SOS tekrar gönderilirse tek ön uyarı', () {
    run(noon, (async) {
      final h = Harness()..monitor.ringConnected();
      h.hb(120);
      h.monitor.handle(const SosMessage(7));
      final d = (h.monitor.phase as PreAlarm).deadline;
      h.advance(async, const Duration(seconds: 2));
      h.monitor.handle(const SosMessage(7));
      expect((h.monitor.phase as PreAlarm).deadline, d);
    });
  });

  test('Pil %20 ve %10 altına ilk inişte bildirim', () {
    run(noon, (async) {
      final h = Harness()..monitor.ringConnected();
      for (final pct in [50, 19, 18, 9, 8]) {
        h.monitor.handle(Heartbeat(seq: pct, moves: 100, intensity: 0, millivolts: 3600, percent: pct, flags: 0));
      }
      expect(h.events.notified.where((k) => k == AppNotificationKind.lowBattery), hasLength(2));
    });
  });

  test('Ani durma kuralı', () {
    expect(Monitor.isAbrupt([120, 120, 120, 10, 10, 120]), isTrue);
    expect(Monitor.isAbrupt([120, 120, 120, 10, 10, 10]), isFalse);
    expect(Monitor.isAbrupt([10, 10, 10, 10, 60, 60]), isFalse);
    expect(Monitor.isAbrupt([]), isFalse);
  });
}
