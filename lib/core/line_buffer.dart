import 'dart:convert';

import 'constants.dart';

/// BLE bildirimlerinden gelen baytları biriktirip `\n` ile biten tam
/// satırlara böler. Bir bildirim yarım satır ya da birden çok satır
/// taşıyabilir.
class LineBuffer {
  LineBuffer({this.maxBytes = K.lineBufferMaxBytes});

  final int maxBytes;
  final List<int> _pending = <int>[];
  bool _discarding = false;

  /// Yeni baytları ekler ve tamamlanan satırları döndürür (`\r` atılır).
  List<String> add(List<int> bytes) {
    final out = <String>[];
    for (final b in bytes) {
      if (b == 0x0A) {
        final line = utf8.decode(_pending, allowMalformed: true).replaceAll('\r', '');
        _pending.clear();
        if (line.isNotEmpty && !_discarding) out.add(line);
        _discarding = false;
      } else if (!_discarding) {
        _pending.add(b);
        if (_pending.length > maxBytes) {
          // KARAR: Sınırı aşan tampon bozuk veri sayılır; bir sonraki `\n`'e kadar atılır.
          _pending.clear();
          _discarding = true;
        }
      }
    }
    return out;
  }

  void clear() {
    _pending.clear();
    _discarding = false;
  }
}
