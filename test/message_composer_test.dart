import 'package:flutter_test/flutter_test.dart';
import 'package:mavera/core/alarm_reason.dart';
import 'package:mavera/core/alarm_record.dart';
import 'package:mavera/core/message_composer.dart';
import 'package:mavera/core/models.dart';

AlarmRecord rec(AlarmReason r, {int? battery = 64, int? pre = 60}) => AlarmRecord(
      id: 'x',
      reason: r,
      triggeredAt: DateTime(2026, 10, 20, 14, 36),
      lastMotionAt: DateTime(2026, 10, 20, 14, 26),
      ringBattery: battery,
      preAlarmSeconds: pre,
    );

void main() {
  const loc = Coord(41.0082, 28.9784, accuracy: 12);
  const ahmet = EmergencyContact(name: 'Ahmet', phone: '0500 111 22 33');

  test('hareketsizlik şablonu (birebir)', () {
    final s = MessageComposer.alarm(
      record: rec(const Inactivity(minutes: 10, abrupt: true)),
      name: 'Meryem',
      location: loc,
      firstContact: ahmet,
    );
    expect(
      s,
      '🚨 ACİL DURUM – Meryem\n'
      '10 dakikadır hiç hareket algılanmadı (hareket aniden kesildi).\n'
      'Son hareket: 14:26 · Alarm: 14:36\n'
      "60 sn'lik uyarıya cevap vermedi.\n"
      '\n'
      'Konum: https://maps.google.com/?q=41.008200,28.978400 (±12 m)\n'
      'Yüzük pili: %64\n'
      '\n'
      'İlk aranacak: Ahmet 0500 111 22 33\n'
      'Konum aşağıda canlı paylaşılıyor.',
    );
  });

  test('konum, pil, kişi yoksa ilgili satırlar çıkar', () {
    final s = MessageComposer.alarm(
      record: rec(const Inactivity(minutes: 3, abrupt: false), battery: null),
      name: 'Meryem',
    );
    expect(s, contains('Konum şu an alınamadı, gelince ayrıca gönderilecek.'));
    expect(s, isNot(contains('Yüzük pili')));
    expect(s, isNot(contains('İlk aranacak')));
    expect(s, isNot(contains('canlı paylaşılıyor')));
    expect(s, isNot(contains('aniden')));
  });

  test('diğer ilk satırlar', () {
    expect(MessageComposer.alarm(record: rec(const Sos(), pre: 15), name: 'Meryem').split('\n').first,
        '🚨 ACİL DURUM – Meryem yüzüğe vurarak yardım istedi');
    expect(MessageComposer.alarm(record: rec(const Tremor()), name: 'Meryem').split('\n').first,
        "🚨 ACİL DURUM – Meryem'de uzun süreli titreme algılandı");
    final manual = MessageComposer.alarm(record: rec(const Manual(), pre: null), name: 'Meryem');
    expect(manual.split('\n').first, '🚨 ACİL DURUM – Meryem uygulamadan yardım istedi');
    expect(manual, isNot(contains('uyarıya cevap vermedi')));
    expect(MessageComposer.extraSos('Meryem', DateTime(2026, 1, 1, 9, 5)), '🚨 Meryem tekrar yardım istedi (09:05)');
    expect(MessageComposer.closed('Meryem', DateTime(2026, 1, 1, 15, 0)),
        '✅ Meryem iyi olduğunu bildirdi, alarm kapatıldı. (15:00)');
    expect(MessageComposer.settingsTest('Meryem'), '🔔 Test: Meryem için Güven Yüzüğü bağlantısı çalışıyor.');
  });

  test('prova ve gecikme önekleri', () {
    final test = MessageComposer.alarm(record: rec(const Sos()), name: 'Meryem', test: true);
    expect(test.split('\n').first, '[TEST] – Bu bir deneme mesajıdır, endişelenmeyin.');
    final late = MessageComposer.alarm(record: rec(const Sos()), name: 'Meryem', lateMinutes: 7);
    expect(late.split('\n').first, '⚠️ Bu mesaj çekim olmadığı için 7 dk geç gitti.');
  });

  test('SMS ASCII dönüşümü', () {
    expect(MessageComposer.toAscii('Güven Yüzüğü ÇŞİÖĞ ı'), 'Guven Yuzugu CSIOG i');
    final sms = MessageComposer.sms(record: rec(const Sos()), name: 'Meryem', location: loc);
    expect(sms, 'ACIL DURUM: Meryem yuzuge vurarak yardim istedi. '
        'Konum: https://maps.google.com/?q=41.008200,28.978400 - Guven Yuzugu');
    expect(sms.runes.every((r) => r < 128), isTrue);
    expect(MessageComposer.sms(record: rec(const Sos()), name: 'Şule'), contains('Konum alinamadi'));
    expect(MessageComposer.smsClosed('Meryem'), 'Meryem iyi oldugunu bildirdi. - Guven Yuzugu');
  });
}
