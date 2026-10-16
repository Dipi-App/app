import 'package:dipi/data/db/app_database.dart';
import 'package:dipi/domain/employer_stats.dart';
import 'package:flutter_test/flutter_test.dart';

WorkEntry entry({
  required int employerId,
  required String date,
  int? wage,
  int outOfPocket = 0,
  String? start,
  String? end,
}) {
  return WorkEntry(
    id: 0,
    employerId: employerId,
    date: date,
    place: null,
    job: null,
    startTime: start,
    endTime: end,
    wageType: 'fixed',
    wageAmount: wage,
    outOfPocketAmount: outOfPocket,
    note: null,
    createdAt: '2024-05-12T00:00:00.000',
  );
}

Payment payment({required int employerId, required int amount}) {
  return Payment(
    id: 0,
    employerId: employerId,
    date: '2024-05-12',
    amount: amount,
    type: 'wage',
    note: null,
    createdAt: '2024-05-12T00:00:00.000',
  );
}

void main() {
  test('employerStats mirrors the settlement summary', () {
    final stats = employerStats(
      entries: [
        entry(employerId: 1, date: '2024-05-12', wage: 100, start: '08:00', end: '12:00'),
        entry(employerId: 1, date: '2024-05-12', wage: null, outOfPocket: 30),
        entry(employerId: 1, date: '2024-05-13', wage: 50),
      ],
      payments: [payment(employerId: 1, amount: 40)],
    );

    expect(stats.entryCount, 3);
    expect(stats.dayCount, 2);
    expect(stats.hours, const Duration(hours: 4));
    expect(stats.wageRial, 150);
    expect(stats.outOfPocketRial, 30);
    expect(stats.paymentsTotalRial, 40);
    expect(stats.earnedRial, 180);
  });

  test('employerStatsByEmployer groups every employer in one pass', () {
    final map = employerStatsByEmployer(
      entries: [
        entry(employerId: 1, date: '2024-05-12', wage: 100),
        entry(employerId: 2, date: '2024-05-12', wage: 900),
        entry(employerId: 1, date: '2024-05-13', wage: 100),
      ],
      payments: [payment(employerId: 2, amount: 300)],
    );

    expect(map.keys.toSet(), {1, 2});
    expect(map[1]!.entryCount, 2);
    expect(map[1]!.dayCount, 2);
    expect(map[1]!.wageRial, 200);
    expect(map[2]!.wageRial, 900);
    expect(map[2]!.paymentsTotalRial, 300);
  });

  test('an employer with only payments still appears', () {
    final map = employerStatsByEmployer(
      entries: const [],
      payments: [payment(employerId: 7, amount: 500)],
    );
    expect(map[7]!.entryCount, 0);
    expect(map[7]!.paymentsTotalRial, 500);
    expect(map[7]!.isEmpty, isFalse);
  });
}
