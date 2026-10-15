import 'package:drift/drift.dart';

import 'app_database.dart';

class PaymentDao {
  PaymentDao(this._db);

  final AppDatabase _db;

  Stream<List<Payment>> watchAll() {
    return (_db.select(_db.payments)
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<Payment>> watchForEmployer(int employerId) {
    return (_db.select(_db.payments)
          ..where((t) => t.employerId.equals(employerId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// [startIso] is inclusive, [endIso] is exclusive.
  Stream<List<Payment>> watchRange(
    String startIso,
    String endIso, {
    int? employerId,
  }) {
    return (_db.select(_db.payments)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(startIso) &
                t.date.isSmallerThanValue(endIso) &
                (employerId == null
                    ? const Constant(true)
                    : t.employerId.equals(employerId)),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// The earliest activity date in the whole ledger, or null when empty.
  Stream<String?> watchEarliestActivity() {
    final query = _db.customSelect(
      'SELECT MIN(d) AS earliest FROM ('
      'SELECT MIN(date) AS d FROM work_entries '
      'UNION ALL '
      'SELECT MIN(date) AS d FROM payments'
      ')',
      readsFrom: {_db.workEntries, _db.payments},
    );
    return query
        .map((row) => row.read<String?>('earliest'))
        .watchSingle();
  }

  Future<List<Payment>> forEmployer(int employerId) {
    return (_db.select(_db.payments)
          ..where((t) => t.employerId.equals(employerId)))
        .get();
  }

  Future<Payment?> byId(int id) {
    return (_db.select(_db.payments)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> create(PaymentsCompanion payment) {
    return _db.into(_db.payments).insert(payment);
  }

  Future<void> update(int id, PaymentsCompanion changes) {
    return (_db.update(_db.payments)..where((t) => t.id.equals(id)))
        .write(changes);
  }

  Future<void> delete(int id) {
    return (_db.delete(_db.payments)..where((t) => t.id.equals(id))).go();
  }

  /// Re-inserts a deleted payment with its original id so "undo" is lossless.
  Future<void> restore(Payment payment) {
    return _db
        .into(_db.payments)
        .insert(payment.toCompanion(true), mode: InsertMode.insertOrReplace);
  }

  /// Total amount paid per employer (all payment types).
  Stream<Map<int, int>> watchTotalsByEmployer() {
    final employer = _db.payments.employerId;
    final total = _db.payments.amount.sum();
    final query = _db.selectOnly(_db.payments)
      ..addColumns([employer, total])
      ..groupBy([employer]);
    return query.watch().map(
      (rows) => {
        for (final row in rows) row.read(employer)!: row.read(total) ?? 0,
      },
    );
  }
}
