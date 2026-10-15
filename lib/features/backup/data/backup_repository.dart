import '../../../core/constants/app_info.dart';
import '../../../data/db/app_database.dart';
import '../domain/backup_document.dart';

enum ImportMode {
  replace('جایگزینی کامل', 'همه داده‌های فعلی پاک و با فایل پشتیبان جایگزین می‌شود.'),
  merge('ادغام', 'داده‌های فایل به داده‌های فعلی اضافه می‌شود و موارد تکراری رد می‌شوند.');

  const ImportMode(this.label, this.description);

  final String label;
  final String description;
}

class ImportResult {
  const ImportResult({
    required this.mode,
    required this.employersAdded,
    required this.entriesAdded,
    required this.paymentsAdded,
    required this.entriesSkipped,
    required this.paymentsSkipped,
  });

  final ImportMode mode;
  final int employersAdded;
  final int entriesAdded;
  final int paymentsAdded;
  final int entriesSkipped;
  final int paymentsSkipped;

  int get totalAdded => employersAdded + entriesAdded + paymentsAdded;

  int get totalSkipped => entriesSkipped + paymentsSkipped;

  String get summaryFa {
    final parts = <String>[
      '$employersAdded کارفرما',
      '$entriesAdded روزکار',
      '$paymentsAdded پرداخت',
    ];
    final skipped = totalSkipped == 0
        ? ''
        : ' — $totalSkipped مورد تکراری رد شد';
    return parts.join('، ') + skipped;
  }
}

class BackupRepository {
  BackupRepository(this._db);

  final AppDatabase _db;

  /// Reads the whole ledger into a document. [includeSettings] also carries the
  /// app settings so a restore on a new phone keeps the theme and currency.
  Future<BackupDocument> buildDocument({
    Map<String, String> settings = const {},
  }) async {
    final employers = await _db.select(_db.employers).get();
    final entries = await _db.select(_db.workEntries).get();
    final payments = await _db.select(_db.payments).get();

    return BackupDocument(
      schemaVersion: BackupDocument.currentSchemaVersion,
      appVersion: AppInfo.version,
      exportedAt: DateTime.now().toIso8601String(),
      employers: [for (final row in employers) BackupEmployer.fromRow(row)],
      workEntries: [for (final row in entries) BackupWorkEntry.fromRow(row)],
      payments: [for (final row in payments) BackupPayment.fromRow(row)],
      settings: settings,
    );
  }

  Future<String> exportJson({Map<String, String> settings = const {}}) async {
    final document = await buildDocument(settings: settings);
    return document.encode();
  }

  Future<ImportResult> import({
    required BackupDocument document,
    required ImportMode mode,
  }) {
    return _db.transaction(() async {
      if (mode == ImportMode.replace) {
        await _db.delete(_db.payments).go();
        await _db.delete(_db.workEntries).go();
        await _db.delete(_db.employers).go();
        return _insertAll(document);
      }
      return _merge(document);
    });
  }

  Future<ImportResult> _insertAll(BackupDocument document) async {
    for (final employer in document.employers) {
      await _db.into(_db.employers).insert(employer.toCompanion());
    }
    for (final entry in document.workEntries) {
      await _db.into(_db.workEntries).insert(entry.toCompanion());
    }
    for (final payment in document.payments) {
      await _db.into(_db.payments).insert(payment.toCompanion());
    }
    return ImportResult(
      mode: ImportMode.replace,
      employersAdded: document.employers.length,
      entriesAdded: document.workEntries.length,
      paymentsAdded: document.payments.length,
      entriesSkipped: 0,
      paymentsSkipped: 0,
    );
  }

  Future<ImportResult> _merge(BackupDocument document) async {
    final existingEmployers = await _db.select(_db.employers).get();
    final byName = {
      for (final employer in existingEmployers)
        employer.name.trim(): employer.id,
    };
    var employersAdded = 0;

    // Backup employer id -> database employer id.
    final idMap = <int, int>{};
    for (final employer in document.employers) {
      final key = employer.name.trim();
      final existing = byName[key];
      if (existing != null) {
        idMap[employer.id] = existing;
        continue;
      }
      final newId = await _db
          .into(_db.employers)
          .insert(employer.toCompanion());
      byName[key] = newId;
      idMap[employer.id] = newId;
      employersAdded++;
    }

    final existingEntries = await _db.select(_db.workEntries).get();
    final entryKeys = {
      for (final entry in existingEntries)
        BackupWorkEntry.fromRow(entry).mergeKey,
    };
    var entriesAdded = 0;
    var entriesSkipped = 0;
    for (final entry in document.workEntries) {
      final mapped = entry.employerId;
      final targetEmployer = idMap[mapped];
      if (targetEmployer == null) {
        entriesSkipped++;
        continue;
      }
      final remapped = BackupWorkEntry(
        id: entry.id,
        employerId: targetEmployer,
        date: entry.date,
        place: entry.place,
        job: entry.job,
        startTime: entry.startTime,
        endTime: entry.endTime,
        wageType: entry.wageType,
        wageAmount: entry.wageAmount,
        outOfPocketAmount: entry.outOfPocketAmount,
        note: entry.note,
        createdAt: entry.createdAt,
      );
      if (entryKeys.contains(remapped.mergeKey)) {
        entriesSkipped++;
        continue;
      }
      await _db.into(_db.workEntries).insert(remapped.toCompanion());
      entryKeys.add(remapped.mergeKey);
      entriesAdded++;
    }

    final existingPayments = await _db.select(_db.payments).get();
    final paymentKeys = {
      for (final payment in existingPayments)
        BackupPayment.fromRow(payment).mergeKey,
    };
    var paymentsAdded = 0;
    var paymentsSkipped = 0;
    for (final payment in document.payments) {
      final targetEmployer = idMap[payment.employerId];
      if (targetEmployer == null) {
        paymentsSkipped++;
        continue;
      }
      final remapped = BackupPayment(
        id: payment.id,
        employerId: targetEmployer,
        date: payment.date,
        amount: payment.amount,
        type: payment.type,
        note: payment.note,
        createdAt: payment.createdAt,
      );
      if (paymentKeys.contains(remapped.mergeKey)) {
        paymentsSkipped++;
        continue;
      }
      await _db.into(_db.payments).insert(remapped.toCompanion());
      paymentKeys.add(remapped.mergeKey);
      paymentsAdded++;
    }

    return ImportResult(
      mode: ImportMode.merge,
      employersAdded: employersAdded,
      entriesAdded: entriesAdded,
      paymentsAdded: paymentsAdded,
      entriesSkipped: entriesSkipped,
      paymentsSkipped: paymentsSkipped,
    );
  }

  Future<void> deleteEverything() {
    return _db.transaction(() async {
      await _db.delete(_db.payments).go();
      await _db.delete(_db.workEntries).go();
      await _db.delete(_db.employers).go();
    });
  }

  Future<int> rowCount() async {
    final employers = await _db.select(_db.employers).get();
    final entries = await _db.select(_db.workEntries).get();
    final payments = await _db.select(_db.payments).get();
    return employers.length + entries.length + payments.length;
  }
}
