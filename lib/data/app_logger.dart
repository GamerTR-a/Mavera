import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';

/// Dosyaya yazan halka tamponlu teknik günlük (son 2000 satır).
///
/// Token'lar maskelenir; konum yalnızca 2 ondalıkla yazılır (`Coord.toString`).
abstract final class AppLogger {
  static final List<String> _lines = <String>[];
  static File? _file;
  static Timer? _flush;

  static final _tokenRe = RegExp(r'\d{6,}:[A-Za-z0-9_-]{20,}');
  static final _coordRe = RegExp(r'(-?\d{1,3}\.\d{2})\d+');

  static Future<void> init(Directory dir) async {
    final f = File('${dir.path}${Platform.pathSeparator}app_log.txt');
    _file = f;
    try {
      if (f.existsSync()) {
        final existing = await f.readAsLines();
        _lines.addAll(existing.length > K.logRingLines
            ? existing.sublist(existing.length - K.logRingLines)
            : existing);
      }
    } on FileSystemException catch (e) {
      debugPrint('Günlük okunamadı: $e');
    }
  }

  /// Hassas veriyi temizler.
  static String sanitize(String s) =>
      s.replaceAll(_tokenRe, '***').replaceAllMapped(_coordRe, (m) => m.group(1) ?? '');

  static void _add(String level, String msg) {
    final t = DateTime.now().toIso8601String();
    final line = '$t $level ${sanitize(msg)}';
    if (kDebugMode) debugPrint(line);
    _lines.add(line);
    if (_lines.length > K.logRingLines) {
      _lines.removeRange(0, _lines.length - K.logRingLines);
    }
    _flush ??= Timer(const Duration(seconds: 3), _write);
  }

  static Future<void> _write() async {
    _flush = null;
    final f = _file;
    if (f == null) return;
    try {
      await f.writeAsString('${_lines.join('\n')}\n', flush: true);
    } on FileSystemException catch (e) {
      debugPrint('Günlük yazılamadı: $e');
    }
  }

  static void i(String msg) => _add('I', msg);
  static void w(String msg) => _add('W', msg);
  static void e(String msg, [Object? error, StackTrace? st]) =>
      _add('E', error == null ? msg : '$msg: $error${st == null ? '' : '\n$st'}');

  /// Paylaşım için son [count] satır.
  static List<String> tail([int count = K.logShareLines]) =>
      _lines.length <= count ? List<String>.of(_lines) : _lines.sublist(_lines.length - count);
}
