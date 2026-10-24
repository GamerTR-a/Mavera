import 'package:sqflite/sqflite.dart';

import '../core/models.dart';

/// Yakın kişiler (alarmda aranacak sıra).
class ContactsRepository {
  ContactsRepository(this._db);
  final Database _db;
  List<EmergencyContact>? _cache;

  Future<List<EmergencyContact>> all() async {
    final c = _cache;
    if (c != null) return c;
    final rows = await _db.query('contacts', orderBy: 'sort_order ASC, id ASC');
    final list = rows
        .map((r) => EmergencyContact(
              id: r['id'] as int?,
              name: r['name'] as String? ?? '',
              phone: r['phone'] as String? ?? '',
              sortOrder: r['sort_order'] as int? ?? 0,
            ))
        .toList();
    _cache = list;
    return list;
  }

  Future<void> add(EmergencyContact c) async {
    final n = (await all()).length;
    await _db.insert('contacts', {'name': c.name.trim(), 'phone': c.phone.trim(), 'sort_order': n});
    _cache = null;
  }

  Future<void> updateContact(EmergencyContact c) async {
    await _db.update('contacts', {'name': c.name.trim(), 'phone': c.phone.trim()},
        where: 'id = ?', whereArgs: [c.id]);
    _cache = null;
  }

  Future<void> remove(int id) async {
    await _db.delete('contacts', where: 'id = ?', whereArgs: [id]);
    await reorder(await _reload());
  }

  Future<List<EmergencyContact>> _reload() async {
    _cache = null;
    return all();
  }

  /// Listeyi verilen sırayla kaydeder.
  Future<void> reorder(List<EmergencyContact> ordered) async {
    final batch = _db.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.update('contacts', {'sort_order': i}, where: 'id = ?', whereArgs: [ordered[i].id]);
    }
    await batch.commit(noResult: true);
    _cache = null;
  }
}
