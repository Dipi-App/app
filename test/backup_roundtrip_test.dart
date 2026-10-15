import 'package:dipi/data/db/app_database.dart';
import 'package:dipi/features/backup/data/backup_repository.dart';
import 'package:dipi/features/backup/domain/backup_document.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late BackupRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = BackupRepository(database);
  });

  tearDown(() => database.close());

  Future<int> seed() async {
    final employerId = await database
        .into(database.employers)
        .insert(
          EmployersCompanion.insert(
            name: 'کارگاه آفتاب',
            color: const Value(0xFFC0562B),
            phone: const Value('09123456789'),
            defaultWageType: const Value('variable'),
            defaultDailyWage: const Value(700000),
            createdAt: '2024-05-01T00:00:00.000',
          ),
        );
    await database
        .into(database.employers)
        .insert(
          EmployersCompanion.insert(
            name: 'آقای رضایی',
            isArchived: const Value(true),
            createdAt: '2024-05-02T00:00:00.000',
          ),
        );
    await database
        .into(database.workEntries)
        .insert(
          WorkEntriesCompanion.insert(
            employerId: employerId,
            date: '2024-05-12',
            createdAt: '2024-05-12T08:00:00.000',
            place: const Value('کارگاه ۲'),
            job: const Value('بنایی'),
            startTime: const Value('08:00'),
            endTime: const Value('16:30'),
            wageType: const Value('variable'),
            wageAmount: const Value(5000000),
            outOfPocketAmount: const Value(45000),
            note: const Value('نکته'),
          ),
        );
    await database
        .into(database.workEntries)
        .insert(
          WorkEntriesCompanion.insert(
            employerId: employerId,
            date: '2024-05-13',
            createdAt: '2024-05-13T08:00:00.000',
          ),
        );
    await database
        .into(database.payments)
        .insert(
          PaymentsCompanion.insert(
            employerId: employerId,
            date: '2024-05-20',
            amount: 2000000,
            createdAt: '2024-05-20T10:00:00.000',
            type: const Value('advance'),
            note: const Value('علی‌الحساب'),
          ),
        );
    return employerId;
  }

  test('export → wipe → import restores everything', () async {
    await seed();
    final json = await repository.exportJson(settings: {'themeChoice': 'dark'});

    await repository.deleteEverything();
    expect(await repository.rowCount(), 0);

    final document = BackupDocument.decode(json);
    expect(document.schemaVersion, BackupDocument.currentSchemaVersion);
    expect(document.employers, hasLength(2));
    expect(document.workEntries, hasLength(2));
    expect(document.payments, hasLength(1));
    expect(document.settings['themeChoice'], 'dark');

    final result = await repository.import(
      document: document,
      mode: ImportMode.replace,
    );
    expect(result.employersAdded, 2);
    expect(result.entriesAdded, 2);
    expect(result.paymentsAdded, 1);
    expect(await repository.rowCount(), 5);

    final employers = await database.select(database.employers).get();
    final restored = employers.firstWhere((e) => e.name == 'کارگاه آفتاب');
    expect(restored.color, 0xFFC0562B);
    expect(restored.phone, '09123456789');
    expect(restored.defaultWageType, 'variable');
    expect(restored.defaultDailyWage, 700000);
    expect(employers.any((e) => e.isArchived), isTrue);

    final entries = await database.select(database.workEntries).get();
    final entry = entries.firstWhere((e) => e.date == '2024-05-12');
    expect(entry.employerId, restored.id);
    expect(entry.place, 'کارگاه ۲');
    expect(entry.startTime, '08:00');
    expect(entry.endTime, '16:30');
    expect(entry.wageAmount, 5000000);
    expect(entry.outOfPocketAmount, 45000);
    expect(entries.any((e) => e.wageAmount == null), isTrue);
  });

  test('round trip through JSON keeps persian text intact', () async {
    await seed();
    final json = await repository.exportJson();
    final document = BackupDocument.decode(json);
    expect(document.employers.first.name, 'کارگاه آفتاب');
    expect(document.workEntries.first.note, 'نکته');
    expect(document.payments.first.note, 'علی‌الحساب');
  });

  test('merging the same backup again adds nothing', () async {
    await seed();
    final document = BackupDocument.decode(await repository.exportJson());

    final result = await repository.import(
      document: document,
      mode: ImportMode.merge,
    );

    expect(result.employersAdded, 0);
    expect(result.entriesAdded, 0);
    expect(result.paymentsAdded, 0);
    expect(result.entriesSkipped, 2);
    expect(result.paymentsSkipped, 1);
    expect(await repository.rowCount(), 5);
  });

  test('merging into another ledger reuses employers by name', () async {
    await seed();
    final document = BackupDocument.decode(await repository.exportJson());

    // A different phone that already has an employer with the same name.
    final other = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(other.close);
    final otherRepository = BackupRepository(other);
    final existingId = await other
        .into(other.employers)
        .insert(
          EmployersCompanion.insert(
            name: 'کارگاه آفتاب',
            createdAt: '2024-01-01T00:00:00.000',
          ),
        );

    final result = await otherRepository.import(
      document: document,
      mode: ImportMode.merge,
    );

    // Only the second (new) employer is added.
    expect(result.employersAdded, 1);
    expect(result.entriesAdded, 2);
    expect(result.paymentsAdded, 1);

    final entries = await other.select(other.workEntries).get();
    expect(entries.every((entry) => entry.employerId == existingId), isTrue);
  });

  test('replace mode clears rows that are not in the backup', () async {
    await seed();
    final json = await repository.exportJson();

    await database
        .into(database.employers)
        .insert(
          EmployersCompanion.insert(
            name: 'بعد از پشتیبان',
            createdAt: '2024-06-01T00:00:00.000',
          ),
        );

    await repository.import(
      document: BackupDocument.decode(json),
      mode: ImportMode.replace,
    );

    final employers = await database.select(database.employers).get();
    expect(employers.map((e) => e.name), isNot(contains('بعد از پشتیبان')));
    expect(employers, hasLength(2));
  });

  group('validation', () {
    test('rejects broken json', () {
      expect(
        () => BackupDocument.decode('{ this is not json'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects a newer schema version', () {
      final document = {
        'schemaVersion': BackupDocument.currentSchemaVersion + 1,
        'employers': const [],
      };
      expect(
        () => BackupDocument.fromJson(document),
        throwsA(
          isA<BackupFormatException>().having(
            (error) => error.message,
            'message',
            contains('نسخه تازه‌تر'),
          ),
        ),
      );
    });

    test('rejects an entry pointing at a missing employer', () {
      final document = {
        'schemaVersion': 1,
        'employers': const [],
        'workEntries': [
          {'id': 1, 'employerId': 99, 'date': '2024-05-12'},
        ],
      };
      expect(
        () => BackupDocument.fromJson(document),
        throwsA(
          isA<BackupFormatException>().having(
            (error) => error.message,
            'message',
            contains('کارفرمایی اشاره می‌کند'),
          ),
        ),
      );
    });

    test('rejects a bad date', () {
      final document = {
        'schemaVersion': 1,
        'employers': [
          {'id': 1, 'name': 'الف'},
        ],
        'workEntries': [
          {'id': 1, 'employerId': 1, 'date': '۱۲ اردیبهشت'},
        ],
      };
      expect(
        () => BackupDocument.fromJson(document),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects a nameless employer', () {
      final document = {
        'schemaVersion': 1,
        'employers': [
          {'id': 1, 'name': '   '},
        ],
      };
      expect(
        () => BackupDocument.fromJson(document),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('accepts a minimal but valid document', () {
      final document = BackupDocument.fromJson({
        'schemaVersion': 1,
        'employers': [
          {'id': 7, 'name': 'الف'},
        ],
        'payments': [
          {'id': 3, 'employerId': 7, 'date': '2024-05-12', 'amount': 500},
        ],
      });
      expect(document.employers.single.id, 7);
      expect(document.payments.single.amount, 500);
      expect(document.workEntries, isEmpty);
    });
  });
}
