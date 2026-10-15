import 'package:dipi/data/db/app_database.dart';
import 'package:dipi/data/db/key_value_dao.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));

  tearDown(() => database.close());

  test('schema is created and core rows round trip', () async {
    final employerId = await database
        .into(database.employers)
        .insert(
          EmployersCompanion.insert(
            name: 'کارگاه آفتاب',
            createdAt: DateTime.now().toIso8601String(),
            color: const Value(0xFF2E7D6F),
          ),
        );

    await database
        .into(database.workEntries)
        .insert(
          WorkEntriesCompanion.insert(
            employerId: employerId,
            date: '2024-05-12',
            createdAt: DateTime.now().toIso8601String(),
            wageAmount: const Value(5000000),
          ),
        );

    final entries = await database.select(database.workEntries).get();
    expect(entries, hasLength(1));
    expect(entries.single.date, '2024-05-12');
    expect(entries.single.wageAmount, 5000000);

    final employers = await database.select(database.employers).get();
    expect(employers.single.name, 'کارگاه آفتاب');
    expect(employers.single.isArchived, isFalse);
  });

  test('foreign keys cascade on delete', () async {
    final employerId = await database
        .into(database.employers)
        .insert(
          EmployersCompanion.insert(
            name: 'کارفرما',
            createdAt: DateTime.now().toIso8601String(),
          ),
        );

    await database
        .into(database.payments)
        .insert(
          PaymentsCompanion.insert(
            employerId: employerId,
            date: '2024-05-12',
            amount: 100000,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );

    await (database.delete(
      database.employers,
    )..where((t) => t.id.equals(employerId))).go();

    expect(await database.select(database.payments).get(), isEmpty);
  });

  test('key value dao persists settings', () async {
    final dao = KeyValueDao(database);
    await dao.write('currencyUnit', 'rial');
    expect(await dao.read('currencyUnit'), 'rial');
    expect(await dao.all(), {'currencyUnit': 'rial'});
    await dao.remove('currencyUnit');
    expect(await dao.read('currencyUnit'), isNull);
  });
}
