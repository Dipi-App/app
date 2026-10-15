import 'package:dipi/data/db/app_database.dart';
import 'package:dipi/data/db/employer_dao.dart';
import 'package:dipi/data/db/payment_dao.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late EmployerDao employers;
  late PaymentDao payments;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    employers = EmployerDao(database);
    payments = PaymentDao(database);
  });

  tearDown(() => database.close());

  Future<int> addEmployer(String name) =>
      employers.create(name: name, color: 0xFF2E7D6F, defaultWageType: 'fixed');

  Future<int> addPayment({
    required int employerId,
    required int amount,
    String date = '2024-05-12',
    String type = 'wage',
    String? note,
  }) {
    return payments.create(
      PaymentsCompanion.insert(
        employerId: employerId,
        date: date,
        amount: amount,
        createdAt: DateTime.now().toIso8601String(),
        type: Value(type),
        note: Value(note),
      ),
    );
  }

  test('creates and lists payments newest first', () async {
    final id = await addEmployer('الف');
    await addPayment(employerId: id, amount: 100, date: '2024-05-10');
    await addPayment(employerId: id, amount: 200, date: '2024-05-12');
    await addPayment(employerId: id, amount: 300, date: '2024-05-11');

    final all = await payments.watchAll().first;
    expect(all.map((p) => p.date), [
      '2024-05-12',
      '2024-05-11',
      '2024-05-10',
    ]);
  });

  test('filters by employer', () async {
    final a = await addEmployer('الف');
    final b = await addEmployer('ب');
    await addPayment(employerId: a, amount: 100);
    await addPayment(employerId: b, amount: 200);

    final forA = await payments.watchForEmployer(a).first;
    expect(forA, hasLength(1));
    expect(forA.single.amount, 100);
  });

  test('updates a payment', () async {
    final id = await addEmployer('الف');
    final paymentId = await addPayment(
      employerId: id,
      amount: 100,
      type: 'wage',
    );

    await payments.update(
      paymentId,
      PaymentsCompanion(
        amount: const Value(750),
        type: Value('advance'),
        note: const Value('علی‌الحساب'),
      ),
    );

    final payment = await payments.byId(paymentId);
    expect(payment!.amount, 750);
    expect(payment.type, 'advance');
    expect(payment.note, 'علی‌الحساب');
  });

  test('restore keeps the original id and values', () async {
    final id = await addEmployer('الف');
    final paymentId = await addPayment(employerId: id, amount: 1234);

    final payment = await payments.byId(paymentId);
    await payments.delete(paymentId);
    expect(await payments.byId(paymentId), isNull);

    await payments.restore(payment!);
    final restored = await payments.byId(paymentId);
    expect(restored, isNotNull);
    expect(restored!.amount, 1234);
  });

  test('totals per employer are aggregated in sql', () async {
    final a = await addEmployer('الف');
    final b = await addEmployer('ب');
    await addPayment(employerId: a, amount: 100);
    await addPayment(employerId: a, amount: 250);
    await addPayment(employerId: b, amount: 40);

    final totals = await payments.watchTotalsByEmployer().first;
    expect(totals[a], 350);
    expect(totals[b], 40);
  });

  test('deleting an employer deletes its payments', () async {
    final id = await addEmployer('الف');
    await addPayment(employerId: id, amount: 100);

    await employers.delete(id);

    expect(await payments.watchAll().first, isEmpty);
  });
}
