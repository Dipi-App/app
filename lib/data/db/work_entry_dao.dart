import 'package:drift/drift.dart';

import 'app_database.dart';

class WorkEntryDao {
  WorkEntryDao(this._db);

  final AppDatabase _db;

  /// [startIso] is inclusive, [endIso] is exclusive. ISO text sorts correctly.
  Stream<List<WorkEntry>> watchRange(String startIso, String endIso) {
    return (_db.select(_db.workEntries)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(startIso) &
                t.date.isSmallerThanValue(endIso),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.date),
            (t) => OrderingTerm(
              expression: t.startTime,
              nulls: NullsOrder.last,
            ),
            (t) => OrderingTerm(expression: t.id),
          ]))
        .watch();
  }

  Stream<List<WorkEntry>> watchForEmployer(int employerId) {
    return (_db.select(_db.workEntries)
          ..where((t) => t.employerId.equals(employerId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id),
          ]))
        .watch();
  }

  Stream<List<WorkEntry>> watchForDate(String isoDate) {
    return (_db.select(_db.workEntries)
          ..where((t) => t.date.equals(isoDate))
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.startTime,
              nulls: NullsOrder.last,
            ),
            (t) => OrderingTerm(expression: t.id),
          ]))
        .watch();
  }

  Future<List<WorkEntry>> forEmployer(int employerId) {
    return (_db.select(_db.workEntries)
          ..where((t) => t.employerId.equals(employerId))
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();
  }

  Future<WorkEntry?> byId(int id) {
    return (_db.select(_db.workEntries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> create(WorkEntriesCompanion entry) {
    return _db.into(_db.workEntries).insert(entry);
  }

  Future<void> update(int id, WorkEntriesCompanion changes) {
    return (_db.update(_db.workEntries)..where((t) => t.id.equals(id)))
        .write(changes);
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.workEntries)..where((t) => t.id.equals(id))).go();
  }

  /// Re-inserts a deleted entry with its original id so "undo" is lossless.
  Future<void> restore(WorkEntry entry) {
    return _db
        .into(_db.workEntries)
        .insert(entry.toCompanion(true), mode: InsertMode.insertOrReplace);
  }

  Stream<List<String>> watchDistinctPlaces() => _watchDistinct(_db.workEntries.place);

  Stream<List<String>> watchDistinctJobs() => _watchDistinct(_db.workEntries.job);

  Stream<List<String>> _watchDistinct(GeneratedColumn<String> column) {
    final query = _db.selectOnly(_db.workEntries, distinct: true)
      ..addColumns([column])
      ..where(column.isNotNull());
    return query.watch().map((rows) {
      final values = rows
          .map((row) => row.read(column))
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
      values.sort();
      return values;
    });
  }

  Future<List<WorkEntry>> pendingWages() {
    return (_db.select(_db.workEntries)
          ..where((t) => t.wageAmount.isNull()))
        .get();
  }

  /// Wage and out-of-pocket sums per employer, without loading every row.
  Stream<Map<int, EntrySums>> watchSumsByEmployer() {
    final employer = _db.workEntries.employerId;
    final wage = _db.workEntries.wageAmount.sum();
    final pocket = _db.workEntries.outOfPocketAmount.sum();
    final query = _db.selectOnly(_db.workEntries)
      ..addColumns([employer, wage, pocket])
      ..groupBy([employer]);
    return query.watch().map(
      (rows) => {
        for (final row in rows)
          row.read(employer)!: EntrySums(
            wageRial: row.read(wage) ?? 0,
            outOfPocketRial: row.read(pocket) ?? 0,
          ),
      },
    );
  }
}

class EntrySums {
  const EntrySums({required this.wageRial, required this.outOfPocketRial});

  final int wageRial;
  final int outOfPocketRial;
}
