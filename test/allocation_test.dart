import 'package:dipi/data/db/app_database.dart';
import 'package:dipi/domain/allocation.dart';
import 'package:flutter_test/flutter_test.dart';

WorkEntry entry({required int id, String date = '2024-05-12', int? wage}) {
  return WorkEntry(
    id: id,
    employerId: 1,
    date: date,
    place: null,
    job: null,
    startTime: null,
    endTime: null,
    wageType: 'fixed',
    wageAmount: wage,
    outOfPocketAmount: 0,
    note: null,
    createdAt: '2024-05-12T00:00:00.000',
  );
}

Payment payment({required int amount}) {
  return Payment(
    id: 0,
    employerId: 1,
    date: '2024-05-12',
    amount: amount,
    type: 'wage',
    note: null,
    createdAt: '2024-05-12T00:00:00.000',
  );
}

const int w = 600000;

void main() {
  group('allocate', () {
    test('a) covers the oldest days first and keeps the remainder as credit', () {
      final result = allocate(
        dailyWageRial: w,
        pendingDaysSorted: [
          entry(id: 1, date: '2024-05-10'),
          entry(id: 2, date: '2024-05-11'),
          entry(id: 3, date: '2024-05-12'),
          entry(id: 4, date: '2024-05-13'),
        ],
        payments: [payment(amount: 1500000)],
      );

      expect(result.hasDailyWage, isTrue);
      expect(result.coveredCount, 2);
      expect(result.paidDays, {1: w, 2: w});
      expect(result.creditRial, 300000);
      expect(result.pendingCount, 2);
      expect(result.pendingDays.map((day) => day.id), [3, 4]);
      expect(result.balanceRial(w), 2 * w - 300000);
    });

    test('b) exactly enough money pays every day with no credit', () {
      final result = allocate(
        dailyWageRial: w,
        pendingDaysSorted: [entry(id: 1), entry(id: 2)],
        payments: [payment(amount: 1200000)],
      );

      expect(result.coveredCount, 2);
      expect(result.pendingCount, 0);
      expect(result.creditRial, 0);
      expect(result.isSettled, isTrue);
      expect(result.balanceRial(w), 0);
    });

    test('c) no payments leaves every day pending', () {
      final result = allocate(
        dailyWageRial: w,
        pendingDaysSorted: [entry(id: 1), entry(id: 2)],
        payments: const [],
      );

      expect(result.coveredCount, 0);
      expect(result.pendingCount, 2);
      expect(result.creditRial, 0);
      expect(result.balanceRial(w), 2 * w);
    });

    test('d) without a daily wage the old behaviour is kept', () {
      final result = allocate(
        dailyWageRial: null,
        pendingDaysSorted: [entry(id: 1), entry(id: 2)],
        payments: [payment(amount: 5000000)],
      );

      expect(result.hasDailyWage, isFalse);
      expect(result.coveredCount, 0);
      expect(result.pendingCount, 2);
      expect(result.creditRial, 0);
    });

    test('e) deleting a payment lets the days go back to pending', () {
      final days = [entry(id: 1), entry(id: 2)];
      final before = allocate(
        dailyWageRial: w,
        pendingDaysSorted: days,
        payments: [payment(amount: 1200000)],
      );
      expect(before.coveredCount, 2);

      final after = allocate(
        dailyWageRial: w,
        pendingDaysSorted: days,
        payments: const [],
      );
      expect(after.coveredCount, 0);
      expect(after.pendingCount, 2);
    });

    test('f) a day with its own wage is ignored by the allocation', () {
      final result = allocateEmployer(
        dailyWageRial: w,
        entries: [
          entry(id: 1, date: '2024-05-10'),
          entry(id: 2, date: '2024-05-11', wage: 999),
          entry(id: 3, date: '2024-05-12'),
        ],
        payments: [payment(amount: w)],
      );

      expect(result.paidDays, {1: w});
      expect(result.pendingDays.map((day) => day.id), [3]);
      expect(result.isPaid(2), isFalse);
    });

    test('g) money beyond every pending day becomes extra credit', () {
      final result = allocate(
        dailyWageRial: w,
        pendingDaysSorted: [entry(id: 1), entry(id: 2)],
        payments: [payment(amount: 2000000)],
      );

      expect(result.coveredCount, 2);
      expect(result.pendingCount, 0);
      expect(result.creditRial, 2000000 - 2 * w);
      // Everything is covered, so the account reads as settled.
      expect(result.balanceRial(w), 0);
    });

    test('sorts pending days oldest first', () {
      final result = allocateEmployer(
        dailyWageRial: w,
        entries: [
          entry(id: 3, date: '2024-05-12'),
          entry(id: 1, date: '2024-05-10'),
          entry(id: 2, date: '2024-05-11'),
        ],
        payments: [payment(amount: w)],
      );

      expect(result.paidDays.keys.single, 1);
      expect(result.pendingDays.map((day) => day.id), [2, 3]);
    });
  });

  group('entryIsPaid', () {
    test('manual wages are always paid', () {
      final allocation = allocate(
        dailyWageRial: w,
        pendingDaysSorted: const [],
        payments: const [],
      );
      expect(entryIsPaid(entry(id: 1, wage: 5), allocation), isTrue);
    });

    test('a pending day is paid only when the allocation covered it', () {
      final allocation = allocate(
        dailyWageRial: w,
        pendingDaysSorted: [entry(id: 1), entry(id: 2)],
        payments: [payment(amount: w)],
      );
      expect(entryIsPaid(entry(id: 1), allocation), isTrue);
      expect(entryIsPaid(entry(id: 2), allocation), isFalse);
    });
  });
}
