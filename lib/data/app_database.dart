import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// sqflite veritabanı: kişiler ve olay geçmişi.
class AppDatabase {
  AppDatabase._(this.db);
  final Database db;

  static Future<AppDatabase> open() async {
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, 'guvenyuzuk.db'),
      version: 1,
      onCreate: (db, v) async {
        await db.execute(
            'CREATE TABLE contacts (id INTEGER PRIMARY KEY, name TEXT NOT NULL, phone TEXT NOT NULL, sort_order INTEGER NOT NULL)');
        await db.execute(
            'CREATE TABLE events (id INTEGER PRIMARY KEY, at INTEGER NOT NULL, kind TEXT NOT NULL, detail TEXT NOT NULL, '
            'moves_snapshot TEXT NOT NULL, sent_to_group INTEGER NOT NULL DEFAULT 0)');
        await db.execute('CREATE INDEX events_at ON events(at)');
      },
    );
    return AppDatabase._(db);
  }
}
