import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:sqflite/sqflite.dart';

import '../core/constants.dart';
import '../core/events.dart';
import '../core/models.dart';
import 'app_logger.dart';

/// Olay geçmişi (sqflite `events`).
class EventLog {
  EventLog(this._db);
  final Database _db;
  final _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  Future<void> add(EventKind kind, String detail, List<int> moves, {bool sentToGroup = false}) async {
    try {
      await _db.insert('events', {
        'at': clock.now().millisecondsSinceEpoch,
        'kind': kind.name,
        'detail': detail,
        'moves_snapshot': jsonEncode(moves),
        'sent_to_group': sentToGroup ? 1 : 0,
      });
      _changes.add(null);
    } on Object catch (e) {
      AppLogger.e('Olay yazılamadı', e);
    }
  }

  static EventEntry _row(Map<String, Object?> r) {
    List<int> moves;
    try {
      final d = jsonDecode(r['moves_snapshot'] as String? ?? '[]');
      moves = d is List ? d.whereType<num>().map((n) => n.toInt()).toList() : <int>[];
    } on FormatException {
      moves = <int>[];
    }
    return EventEntry(
      id: r['id'] as int?,
      at: DateTime.fromMillisecondsSinceEpoch(r['at'] as int? ?? 0),
      kind: r['kind'] as String? ?? '',
      detail: r['detail'] as String? ?? '',
      movesSnapshot: moves,
      sentToGroup: (r['sent_to_group'] as int? ?? 0) == 1,
    );
  }

  Future<List<EventEntry>> recent({int limit = 3}) async {
    final rows = await _db.query('events', orderBy: 'at DESC, id DESC', limit: limit);
    return rows.map(_row).toList();
  }

  Future<List<EventEntry>> since(DateTime from) async {
    final rows = await _db.query('events',
        where: 'at >= ?', whereArgs: [from.millisecondsSinceEpoch], orderBy: 'at DESC, id DESC');
    return rows.map(_row).toList();
  }

  /// 30 günden eski kayıtları siler.
  Future<void> purgeOld() async {
    final cutoff = clock.now().subtract(K.eventRetention).millisecondsSinceEpoch;
    await _db.delete('events', where: 'at < ?', whereArgs: [cutoff]);
  }

  Future<void> clear() async {
    await _db.delete('events');
    _changes.add(null);
  }

  /// CSV (tarih, tür, açıklama, gruba_gitti). Token içermez.
  static String toCsv(List<EventEntry> events, String Function(String kind) label) {
    String esc(String s) => '"${s.replaceAll('"', '""')}"';
    final b = StringBuffer('tarih,tür,açıklama,gruba_gitti\n');
    for (final e in events) {
      final t = e.at;
      final date = '${t.year}-${_pad(t.month)}-${_pad(t.day)} ${_pad(t.hour)}:${_pad(t.minute)}';
      b.writeln('$date,${esc(label(e.kind))},${esc(e.detail)},${e.sentToGroup ? 'evet' : 'hayır'}');
    }
    return b.toString();
  }

  static String _pad(int v) => v.toString().padLeft(2, '0');

  Future<void> dispose() => _changes.close();
}
