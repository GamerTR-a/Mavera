import 'dart:convert';
import 'dart:io';

import '../core/alarm_record.dart';
import 'app_logger.dart';

/// Bekleyen alarmın kalıcı deposu.
abstract class PendingAlarmStore {
  Future<void> save(AlarmRecord r);
  Future<AlarmRecord?> load();
  Future<void> clear();
}

/// `pending_alarm.json`: geçici dosyaya yaz → yeniden adlandır (atomik).
class FilePendingAlarmStore implements PendingAlarmStore {
  FilePendingAlarmStore(Directory dir)
      : _file = File('${dir.path}${Platform.pathSeparator}pending_alarm.json'),
        _tmp = File('${dir.path}${Platform.pathSeparator}pending_alarm.json.tmp');

  final File _file;
  final File _tmp;
  Future<void> _queue = Future<void>.value();

  Future<void> _serial(Future<void> Function() op) {
    final next = _queue.then((_) => op());
    _queue = next.catchError((Object e) => AppLogger.e('Bekleyen alarm deposu', e));
    return next;
  }

  @override
  Future<void> save(AlarmRecord r) => _serial(() async {
        await _tmp.writeAsString(jsonEncode(r.toJson()), flush: true);
        await _tmp.rename(_file.path);
      });

  @override
  Future<AlarmRecord?> load() async {
    await _queue;
    try {
      if (!_file.existsSync()) return null;
      final j = jsonDecode(await _file.readAsString());
      if (j is Map<String, Object?>) return AlarmRecord.fromJson(j);
    } on Object catch (e) {
      AppLogger.e('Bekleyen alarm okunamadı', e);
    }
    return null;
  }

  @override
  Future<void> clear() => _serial(() async {
        if (_file.existsSync()) await _file.delete();
      });
}

/// Testler için bellek içi depo.
class MemoryPendingAlarmStore implements PendingAlarmStore {
  String? json;

  @override
  Future<void> save(AlarmRecord r) async => json = jsonEncode(r.toJson());

  @override
  Future<AlarmRecord?> load() async {
    final j = json;
    if (j == null) return null;
    return AlarmRecord.fromJson(jsonDecode(j) as Map<String, Object?>);
  }

  @override
  Future<void> clear() async => json = null;
}
