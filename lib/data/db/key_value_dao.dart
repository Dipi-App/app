import 'package:drift/drift.dart';

import 'app_database.dart';

class KeyValueDao {
  KeyValueDao(this._db);

  final AppDatabase _db;

  Future<Map<String, String>> all() async {
    final rows = await _db.select(_db.keyValues).get();
    return {
      for (final row in rows)
        if (row.value != null) row.key: row.value!,
    };
  }

  Future<String?> read(String key) async {
    final row =
        await (_db.select(_db.keyValues)..where((t) => t.key.equals(key)))
            .getSingleOrNull();
    return row?.value;
  }

  Future<void> write(String key, String value) {
    return _db
        .into(_db.keyValues)
        .insertOnConflictUpdate(
          KeyValuesCompanion.insert(key: key, value: Value(value)),
        );
  }

  Future<void> remove(String key) {
    return (_db.delete(_db.keyValues)..where((t) => t.key.equals(key))).go();
  }

  Future<void> clear() => _db.delete(_db.keyValues).go();
}
