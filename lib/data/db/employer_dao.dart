import 'package:drift/drift.dart';

import 'app_database.dart';

class EmployerDao {
  EmployerDao(this._db);

  final AppDatabase _db;

  Stream<List<Employer>> watchAll({bool includeArchived = false}) {
    final query = _db.select(_db.employers)
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    return query.watch();
  }

  Stream<Employer?> watchById(int id) {
    return (_db.select(_db.employers)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<Employer?> byId(int id) {
    return (_db.select(_db.employers)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<Employer>> all({bool includeArchived = true}) {
    final query = _db.select(_db.employers)
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    return query.get();
  }

  Future<int> create({
    required String name,
    required int color,
    String? phone,
    String? note,
    required String defaultWageType,
    int? defaultDailyWage,
  }) {
    return _db
        .into(_db.employers)
        .insert(
          EmployersCompanion.insert(
            name: name,
            color: Value(color),
            phone: Value(phone),
            note: Value(note),
            defaultWageType: Value(defaultWageType),
            defaultDailyWage: Value(defaultDailyWage),
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
  }

  Future<void> update(Employer employer) {
    return _db.update(_db.employers).replace(employer);
  }

  Future<void> patch(int id, EmployersCompanion changes) {
    return (_db.update(_db.employers)..where((t) => t.id.equals(id)))
        .write(changes);
  }

  Future<void> setArchived(int id, bool archived) {
    return patch(id, EmployersCompanion(isArchived: Value(archived)));
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.employers)..where((t) => t.id.equals(id))).go();
  }
}
