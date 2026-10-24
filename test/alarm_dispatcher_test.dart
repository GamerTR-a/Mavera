import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavera/core/alarm_reason.dart';
import 'package:mavera/core/alarm_record.dart';
import 'package:mavera/core/events.dart';
import 'package:mavera/core/models.dart';
import 'package:mavera/data/pending_alarm_store.dart';
import 'package:mavera/services/alarm_dispatcher.dart';

import 'fakes.dart';

class Rig {
  Rig({SmsMode smsMode = SmsMode.fallback, Coord? coord = const Coord(41, 29, accuracy: 10)}) {
    location = FakeLocation(coord);
    dispatcher = build(smsMode);
  }

  final telegram = FakeTelegram();
  late final FakeLocation location;
  final sms = FakeSms();
  final store = MemoryPendingAlarmStore();
  final events = FakeEvents();
  late AlarmDispatcher dispatcher;

  AlarmDispatcher build(SmsMode smsMode) => AlarmDispatcher(
        settings: () => DispatchSettings(
          personName: 'Meryem',
          chatId: '-100123',
          smsMode: smsMode,
          smsFallbackSeconds: 60,
        ),
        token: () async => '123456:ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        contacts: () async => const [EmergencyContact(id: 1, name: 'Ahmet', phone: '05001112233')],
        telegram: telegram,
        location: location,
        sms: sms,
        store: store,
        events: events,
      );

  AlarmRecord record() => AlarmRecord(
        id: 'a1',
        reason: const Inactivity(minutes: 3, abrupt: true),
        triggeredAt: clock.now(),
        lastMotionAt: clock.now().subtract(const Duration(minutes: 4)),
        ringBattery: 64,
        preAlarmSeconds: 60,
      );

  void advance(FakeAsync async, Duration d) {
    for (var i = 0; i < d.inSeconds; i++) {
      async.elapse(const Duration(seconds: 1));
      dispatcher.tick();
    }
    async.flushMicrotasks();
  }
}

void run(void Function(FakeAsync async) body) {
  fakeAsync((async) {
    withClock(async.getClock(DateTime(2026, 10, 20, 14, 36)), () => body(async));
  });
}

void main() {
  test('İnternet varken: metin + canlı konum, teslim bildirimi', () {
    run((async) {
      final r = Rig();
      r.dispatcher.dispatch(r.record());
      r.advance(async, const Duration(seconds: 2));
      expect(r.telegram.messages, hasLength(1));
      expect(r.telegram.messages.first, startsWith('🚨 ACİL DURUM – Meryem'));
      expect(r.telegram.liveSent, hasLength(1));
      expect(r.dispatcher.current?.delivered, isTrue);
      expect(r.events.notified, contains(AppNotificationKind.delivered));
      expect(r.events.sentToGroup, contains(EventKind.alarmSent));
    });
  });

  test('Ağ hatasında 30 sn\'de bir yeniden deneme, 2 dk bildirimi, gecikme notu', () {
    run((async) {
      final r = Rig(smsMode: SmsMode.off);
      r.telegram.failing = true;
      r.dispatcher.dispatch(r.record());
      r.advance(async, const Duration(seconds: 1));
      expect(r.dispatcher.current?.attempts, 1);
      r.advance(async, const Duration(seconds: 30));
      expect(r.dispatcher.current?.attempts, 2);
      r.advance(async, const Duration(seconds: 90));
      expect(r.events.notified.where((k) => k == AppNotificationKind.failed), hasLength(1));
      r.advance(async, const Duration(seconds: 60));
      expect(r.events.notified.where((k) => k == AppNotificationKind.failed), hasLength(1));
      expect(r.telegram.messages, isEmpty);
      r.telegram.failing = false;
      r.advance(async, const Duration(seconds: 31));
      expect(r.telegram.messages, hasLength(1));
      expect(r.telegram.messages.first, startsWith('⚠️ Bu mesaj çekim olmadığı için 3 dk geç gitti.'));
      expect(r.events.logs, contains(EventKind.alarmDeliveredLate));
    });
  });

  test('fallback SMS tam bir kez ve smsFallbackSeconds sonra', () {
    run((async) {
      final r = Rig();
      r.telegram.failing = true;
      r.dispatcher.dispatch(r.record());
      r.advance(async, const Duration(seconds: 58));
      expect(r.sms.sends, isEmpty);
      r.advance(async, const Duration(seconds: 3));
      expect(r.sms.sends, hasLength(1));
      expect(r.sms.sends.first, startsWith('ACIL DURUM: Meryem hareketsiz kaldi.'));
      r.advance(async, const Duration(minutes: 5));
      expect(r.sms.sends, hasLength(1));
      expect(r.dispatcher.current?.smsSent, isTrue);
    });
  });

  test('Telegram zamanında giderse fallback SMS gitmez', () {
    run((async) {
      final r = Rig();
      r.dispatcher.dispatch(r.record());
      r.advance(async, const Duration(minutes: 3));
      expect(r.sms.sends, isEmpty);
    });
  });

  test('always modunda SMS hemen gider', () {
    run((async) {
      final r = Rig(smsMode: SmsMode.always);
      r.dispatcher.dispatch(r.record());
      r.advance(async, const Duration(seconds: 1));
      expect(r.sms.sends, hasLength(1));
    });
  });

  test('Konum yoksa metin konumsuz gider, konum gelince canlı konum ayrıca', () {
    run((async) {
      final r = Rig(coord: null);
      r.dispatcher.dispatch(r.record());
      r.advance(async, const Duration(seconds: 2));
      expect(r.telegram.messages.first, contains('Konum şu an alınamadı'));
      expect(r.telegram.liveSent, isEmpty);
      r.location.coord = const Coord(41, 29);
      r.advance(async, const Duration(seconds: 65));
      expect(r.telegram.liveSent, hasLength(1));
    });
  });

  test('Diskten devam: uygulama yeniden başlayınca bekleyen alarm gönderilir', () {
    run((async) {
      final r = Rig(smsMode: SmsMode.off);
      r.telegram.failing = true;
      r.dispatcher.dispatch(r.record());
      r.advance(async, const Duration(seconds: 5));
      expect(r.store.json, isNotNull);

      // "Yeniden başlatma": yeni dispatcher aynı depoyla.
      r.telegram.failing = false;
      final d2 = r.build(SmsMode.off);
      AlarmRecord? restored;
      d2.resumePendingIfAny().then((x) => restored = x);
      async.flushMicrotasks();
      expect(restored, isNotNull);
      d2.tick();
      async.flushMicrotasks();
      expect(r.telegram.messages, hasLength(1));
      expect(d2.current?.delivered, isTrue);
    });
  });

  test('Kapatma: kapatma mesajı + canlı konum durdurma + kayıt silinir', () {
    run((async) {
      final r = Rig();
      r.dispatcher.dispatch(r.record());
      r.advance(async, const Duration(seconds: 2));
      expect(r.dispatcher.current?.liveMessageId, 99);
      r.dispatcher.close(byUser: true);
      r.advance(async, const Duration(seconds: 1));
      expect(r.telegram.messages.last, startsWith('✅ Meryem iyi olduğunu bildirdi, alarm kapatıldı.'));
      expect(r.telegram.stopped, [99]);
      expect(r.store.json, isNull);
      expect(r.dispatcher.current, isNull);
    });
  });

  test('Teslim edilmemiş alarm kapatılırsa gruba hiçbir şey gitmez', () {
    run((async) {
      final r = Rig(smsMode: SmsMode.off);
      r.telegram.failing = true;
      r.dispatcher.dispatch(r.record());
      r.advance(async, const Duration(seconds: 5));
      r.dispatcher.close(byUser: true);
      r.telegram.failing = false;
      r.advance(async, const Duration(minutes: 2));
      expect(r.telegram.messages, isEmpty);
    });
  });

  test('Teslimden sonra canlı konum 60 sn\'de bir güncellenir', () {
    run((async) {
      final r = Rig();
      r.dispatcher.dispatch(r.record());
      r.advance(async, const Duration(seconds: 2));
      r.location.live$.add(const Coord(41.001, 29.001));
      r.advance(async, const Duration(seconds: 61));
      expect(r.telegram.liveEdits, hasLength(1));
    });
  });

  test('Alarm açıkken ikinci dispatch yok sayılır', () {
    run((async) {
      final r = Rig();
      r.dispatcher.dispatch(r.record());
      r.dispatcher.dispatch(r.record());
      r.advance(async, const Duration(seconds: 2));
      expect(r.telegram.messages, hasLength(1));
    });
  });
}
