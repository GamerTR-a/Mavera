import 'alarm_reason.dart';
import 'alarm_record.dart';
import 'models.dart';

/// Telegram ve SMS mesaj şablonları (Bölüm 7.3 / 7.4, birebir).
abstract final class MessageComposer {
  static String hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String _coord(double v) => v.toStringAsFixed(6);

  static String mapsUrl(Coord c) => 'https://maps.google.com/?q=${_coord(c.lat)},${_coord(c.lon)}';

  /// Alarm metni.
  ///
  /// [lateMinutes] > 0 ise başa gecikme notu eklenir; [test] ise prova satırı.
  static String alarm({
    required AlarmRecord record,
    required String name,
    Coord? location,
    EmergencyContact? firstContact,
    int lateMinutes = 0,
    bool test = false,
  }) {
    final r = record.reason;
    final lines = <String>[];
    if (lateMinutes > 0) {
      lines.add('⚠️ Bu mesaj çekim olmadığı için $lateMinutes dk geç gitti.');
    }
    if (test) lines.add('[TEST] – Bu bir deneme mesajıdır, endişelenmeyin.');

    final alarmAt = hhmm(record.triggeredAt);
    switch (r) {
      case Inactivity(:final minutes, :final abrupt):
        final idle = record.triggeredAt.difference(record.lastMotionAt).inMinutes;
        final dk = idle > minutes ? idle : minutes;
        lines
          ..add('🚨 ACİL DURUM – $name')
          ..add('$dk dakikadır hiç hareket algılanmadı${abrupt ? ' (hareket aniden kesildi)' : ''}.')
          ..add('Son hareket: ${hhmm(record.lastMotionAt)} · Alarm: $alarmAt');
      case Sos():
        lines
          ..add('🚨 ACİL DURUM – $name yüzüğe vurarak yardım istedi')
          ..add('Alarm: $alarmAt');
      case Tremor():
        lines
          ..add("🚨 ACİL DURUM – $name'de uzun süreli titreme algılandı")
          ..add('En az 20 sn kesintisiz titreme · Alarm: $alarmAt');
      case Manual():
        lines
          ..add('🚨 ACİL DURUM – $name uygulamadan yardım istedi')
          ..add('Alarm: $alarmAt');
    }
    final pre = record.preAlarmSeconds;
    if (pre != null && r is! Manual) {
      lines.add("$pre sn'lik uyarıya cevap vermedi.");
    }

    lines.add('');
    if (location != null) {
      final acc = location.accuracy;
      final accText = acc == null ? '' : ' (±${acc.round()} m)';
      lines.add('Konum: ${mapsUrl(location)}$accText');
    } else {
      lines.add('Konum şu an alınamadı, gelince ayrıca gönderilecek.');
    }
    final bat = record.ringBattery;
    if (bat != null) lines.add('Yüzük pili: %$bat');

    final c = firstContact;
    if (c != null || location != null) lines.add('');
    if (c != null) lines.add('İlk aranacak: ${c.name} ${c.phone}');
    if (location != null) lines.add('Konum aşağıda canlı paylaşılıyor.');
    return lines.join('\n').trimRight();
  }

  /// Alarm açıkken gelen ikinci SOS.
  static String extraSos(String name, DateTime at) => '🚨 $name tekrar yardım istedi (${hhmm(at)})';

  /// Alarm kapatma mesajı.
  static String closed(String name, DateTime at) =>
      '✅ $name iyi olduğunu bildirdi, alarm kapatıldı. (${hhmm(at)})';

  /// Ayarlardaki test mesajı.
  static String settingsTest(String name) => '🔔 Test: $name için Güven Yüzüğü bağlantısı çalışıyor.';

  /// Konum sonradan gelince gönderilen kısa not.
  static String locationLate(Coord c) => 'Konum: ${mapsUrl(c)}';

  // ------------------------------------------------------------------ SMS

  static String _shortReason(AlarmRecord r) => switch (r.reason) {
        Inactivity() => 'hareketsiz kaldi',
        Sos() => 'yuzuge vurarak yardim istedi',
        Tremor() => 'uzun sureli titreme yasiyor',
        Manual() => 'uygulamadan yardim istedi',
      };

  /// KARAR: SMS'te Türkçe karakter kullanılmaz; GSM-7 ile tek parçaya daha çok
  /// karakter sığar (Türkçe karakter mesajı 70'lik parçalara böler).
  static String sms({required AlarmRecord record, required String name, Coord? location}) {
    final loc = location == null ? 'Konum alinamadi' : 'Konum: ${mapsUrl(location)}';
    return toAscii('ACIL DURUM: $name ${_shortReason(record)}. $loc - Guven Yuzugu');
  }

  static String smsClosed(String name) => toAscii('$name iyi oldugunu bildirdi. - Guven Yuzugu');

  static String smsTest(String name) => toAscii('Test: $name icin Guven Yuzugu SMS yedegi calisiyor.');

  static const _tr = {
    'ç': 'c', 'Ç': 'C', 'ğ': 'g', 'Ğ': 'G', 'ı': 'i', 'İ': 'I',
    'ö': 'o', 'Ö': 'O', 'ş': 's', 'Ş': 'S', 'ü': 'u', 'Ü': 'U',
    'â': 'a', 'Â': 'A', 'î': 'i', 'û': 'u',
  };

  /// Türkçe karakterleri ASCII karşılığına çevirir, kalan ASCII dışı karakterleri atar.
  static String toAscii(String s) {
    final b = StringBuffer();
    for (final ch in s.runes) {
      final c = String.fromCharCode(ch);
      final m = _tr[c];
      if (m != null) {
        b.write(m);
      } else if (ch < 128) {
        b.write(c);
      }
    }
    return b.toString();
  }
}
