import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavera/core/alarm_reason.dart';
import 'package:mavera/core/alarm_record.dart';
import 'package:mavera/core/health_check.dart';
import 'package:mavera/core/models.dart';
import 'package:mavera/core/monitor_phase.dart';
import 'package:mavera/providers/providers.dart';
import 'package:mavera/services/alarm_dispatcher.dart';
import 'package:mavera/services/app_core.dart';
import 'package:mavera/services/ring/ring_transport.dart';
import 'package:mavera/ui/components/shield.dart';
import 'package:mavera/ui/main/alarm_active_screen.dart';
import 'package:mavera/ui/main/pre_alarm_screen.dart';

import '../fakes.dart';

CoreView _view(MonitorPhase phase) => CoreView(
      phase: phase,
      lastMotionAt: clock.now(),
      ringBattery: 64,
      ringMillivolts: 3920,
      recentMoves: const [],
      connection: RingConnectionState.connected,
      rssi: -55,
      lastSignalAt: clock.now(),
      deviceName: 'GuvenYuzuk',
      delivery: Delivered(clock.now()),
      record: phase is AlarmActive ? phase.record : null,
      shield: ShieldLevel.protected,
      issues: const [],
      batteryRemaining: null,
      lastFullAt: null,
      heartbeatCount: 0,
    );

class _FakeView extends CoreViewNotifier {
  _FakeView(this.v);
  final CoreView v;
  @override
  CoreView build() => v;
}

class _FakeContacts extends ContactsNotifier {
  @override
  Future<List<EmergencyContact>> build() async => const [EmergencyContact(id: 1, name: 'Ahmet', phone: '0500')];
}

void main() {
  testWidgets('Ön uyarı: "İyiyim" tek dokunuşla imFine çağırır', (tester) async {
    var calls = 0;
    await tester.pumpWidget(wrap(Scaffold(
      body: PreAlarmView(
        reason: const Inactivity(minutes: 10, abrupt: true),
        remaining: 42,
        total: 60,
        onImFine: () => calls++,
        onSendNow: () {},
      ),
    )));
    expect(find.text('Hareketsizlik algılandı'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    await tester.tap(find.text('İyiyim'));
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('Ön uyarı metin ölçeği 2.0\'da taşmadan çizilir', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(Builder(
      builder: (c) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(2)),
        child: Scaffold(
          body: PreAlarmView(
            reason: const Sos(),
            remaining: 12,
            total: 15,
            motionSeen: true,
            onImFine: () {},
            onSendNow: () {},
          ),
        ),
      ),
    )));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Alarm ekranı: kapatma onay ister', (tester) async {
    final record = AlarmRecord(
      id: 'r',
      reason: const Sos(),
      triggeredAt: DateTime(2026, 1, 1, 14, 36),
      lastMotionAt: DateTime(2026, 1, 1, 14, 30),
      deliveredAt: DateTime(2026, 1, 1, 14, 36, 10),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        coreViewProvider.overrideWith(() => _FakeView(_view(AlarmActive(record)))),
        contactsProvider.overrideWith(_FakeContacts.new),
      ],
      child: wrap(const AlarmActiveScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Yakınlarına haber verildi'), findsOneWidget);
    expect(find.text('Mesaj gruba ulaştı'), findsOneWidget);
    expect(find.text('Ahmet'), findsOneWidget);
    await tester.tap(find.text('İyiyim, alarmı kapat'));
    await tester.pumpAndSettle();
    expect(find.text('Yakınlarına iyi olduğun bildirilsin mi?'), findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(find.text('Yakınlarına iyi olduğun bildirilsin mi?'), findsNothing);
  });

  testWidgets('Kalkan üç seviyeyi doğru gösterir', (tester) async {
    for (final (level, label) in [
      (ShieldLevel.protected, 'Koruma açık'),
      (ShieldLevel.attention, 'Dikkat'),
      (ShieldLevel.unprotected, 'Koruma yok'),
    ]) {
      await tester.pumpWidget(wrap(Scaffold(body: Center(child: Shield(level: level)))));
      expect(find.text(label), findsOneWidget);
      expect(find.bySemanticsLabel('Koruma durumu: $label'), findsOneWidget);
    }
  });
}
