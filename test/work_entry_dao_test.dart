import 'package:dipi/data/db/app_database.dart';
import 'package:dipi/data/db/employer_dao.dart';
import 'package:dipi/data/db/work_entry_dao.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late EmployerDao employers;
  late WorkEntryDao entries;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    employers = EmployerDao(database);
    entries = WorkEntryDao(database);
  });

  tearDown(() => database.close());

  Future<int> addEmployer(String name, {int color = 0xFF2E7D6F}) {
    return employers.create(
      name: name,
      color: color,
      defaultWageType: 'fixed',
    );
  }

  Future<int> addEntry({
    required int employerId,
    required String date,
    int? wage,
    String? place,
    String? job,
    String? start,
    String? end,
  }) {
    return entries.create(
      WorkEntriesCompanion.insert(
        employerId: employerId,
        date: date,
        createdAt: DateTime.now().toIso8601String(),
        place: Value(place),
        job: Value(job),
        startTime: Value(start),
        endTime: Value(end),
        wageAmount: Value(wage),
      ),
    );
  }

  group('employer dao', () {
    test('creates, lists and archives', () async {
      final id = await addEmployer('کارگاه آفتاب');
      await addEmployer('کارگاه ماه');

      expect((await employers.all()).length, 2);
      expect((await employers.all(includeArchived: false)).length, 2);

      await employers.setArchived(id, true);

      final active = await employers.all(includeArchived: false);
      expect(active.map((e) => e.name), ['کارگاه ماه']);
      expect((await employers.all()).length, 2);
    });

    test('patches a single field', () async {
      final id = await addEmployer('الف');
      await employers.patch(
        id,
        EmployersCompanion(
          name: const Value('ب'),
          color: const Value(0xFFC0562B),
        ),
      );
      final employer = await employers.byId(id);
      expect(employer!.name, 'ب');
      expect(employer.color, 0xFFC0562B);
      expect(employer.defaultWageType, 'fixed');
    });

    test('deleting an employer cascades to its entries', () async {
      final id = await addEmployer('الف');
      await addEntry(employerId: id, date: '2024-05-12', wage: 100);

      await employers.delete(id);

      expect(await database.select(database.workEntries).get(), isEmpty);
    });
  });

  group('work entry dao', () {
    test('range query is inclusive of the start and exclusive of the end',
        () async {
      final id = await addEmployer('الف');
      await addEntry(employerId: id, date: '2024-04-19');
      await addEntry(employerId: id, date: '2024-04-20');
      await addEntry(employerId: id, date: '2024-05-20');
      await addEntry(employerId: id, date: '2024-05-21');

      final range = await entries.watchRange('2024-04-20', '2024-05-21').first;
      expect(range.map((e) => e.date), ['2024-04-20', '2024-05-20']);
    });

    test('range query can be limited to one employer', () async {
      final a = await addEmployer('الف');
      final b = await addEmployer('ب');
      await addEntry(employerId: a, date: '2024-05-01');
      await addEntry(employerId: b, date: '2024-05-02');

      final range = await entries
          .watchRange('2024-05-01', '2024-06-01', employerId: b)
          .first;
      expect(range, hasLength(1));
      expect(range.single.employerId, b);
    });

    test('sums per employer are aggregated in sql', () async {
      final a = await addEmployer('الف');
      final b = await addEmployer('ب');
      await addEntry(employerId: a, date: '2024-05-01', wage: 100);
      await addEntry(employerId: a, date: '2024-05-02', wage: 50);
      await addEntry(employerId: b, date: '2024-05-03');

      final sums = await entries.watchSumsByEmployer().first;
      expect(sums[a]!.wageRial, 150);
      expect(sums[a]!.outOfPocketRial, 0);
      expect(sums[b]!.wageRial, 0);
    });

    test('orders a day by start time', () async {
      final id = await addEmployer('الف');
      await addEntry(employerId: id, date: '2024-05-12', start: '14:00');
      await addEntry(employerId: id, date: '2024-05-12', start: '08:00');

      final day = await entries.watchForDate('2024-05-12').first;
      expect(day.map((e) => e.startTime), ['08:00', '14:00']);
    });

    test('restore keeps the original id', () async {
      final id = await addEmployer('الف');
      final entryId = await addEntry(
        employerId: id,
        date: '2024-05-12',
        wage: 5000,
      );

      final entry = await entries.byId(entryId);
      await entries.delete(entryId);
      expect(await entries.byId(entryId), isNull);

      await entries.restore(entry!);
      final restored = await entries.byId(entryId);
      expect(restored, isNotNull);
      expect(restored!.wageAmount, 5000);
    });

    test('distinct places and jobs ignore blanks and duplicates', () async {
      final id = await addEmployer('الف');
      await addEntry(employerId: id, date: '2024-05-12', place: 'کارگاه ۲');
      await addEntry(employerId: id, date: '2024-05-13', place: 'کارگاه ۲');
      await addEntry(employerId: id, date: '2024-05-14', place: '  ');
      await addEntry(employerId: id, date: '2024-05-14', job: 'بنایی');

      expect(await entries.watchDistinctPlaces().first, ['کارگاه ۲']);
      expect(await entries.watchDistinctJobs().first, ['بنایی']);
    });

    test('finds entries with pending wages', () async {
      final id = await addEmployer('الف');
      await addEntry(employerId: id, date: '2024-05-12');
      await addEntry(employerId: id, date: '2024-05-13', wage: 1000);

      final pending = await entries.pendingWages();
      expect(pending.length, 1);
      expect(pending.single.date, '2024-05-12');
    });
  });
}
