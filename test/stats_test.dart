import 'package:dipi/core/utils/jalali_utils.dart';
import 'package:dipi/data/db/app_database.dart';
import 'package:dipi/domain/enums.dart';
import 'package:dipi/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

WorkEntry entry({
  int employerId = 1,
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

Payment payment({
  int employerId = 1,
  required String date,
  required int amount,
  PaymentType type = PaymentType.wage,
}) {
  return Payment(
    id: 0,
    employerId: employerId,
    date: date,
    amount: amount,
    type: type.name,
    note: null,
    createdAt: '2024-05-12T00:00:00.000',
  );
}

void main() {
  final farvardin = jalaliToDateTime(1403, 1, 1);
  final khordad = jalaliToDateTime(1403, 3, 1);

  group('monthlySeries', () {
    test('keeps every month of the range, even empty ones', () {
      final series = monthlySeries(
        entries: const [],
        payments: const [],
        from: farvardin,
        to: khordad,
      );
      expect(series, hasLength(3));
      expect(series.map((p) => p.monthKey), [
        '2024-03-20',
        '2024-04-20',
        '2024-05-21',
      ]);
      expect(series.every((p) => p.isEmpty), isTrue);
      expect(series.every((p) => p.balanceRial == 0), isTrue);
    });

    test('buckets entries by jalali month, not by gregorian month', () {
      final series = monthlySeries(
        entries: [
          // Last day of Farvardin and first day of Ordibehesht.
          entry(date: '2024-04-19', wage: 100),
          entry(date: '2024-04-20', wage: 200),
        ],
        payments: const [],
        from: farvardin,
        to: khordad,
      );
      expect(series[0].wageRial, 100);
      expect(series[1].wageRial, 200);
    });

    test('ignores activity outside the range', () {
      final series = monthlySeries(
        entries: [
          entry(date: '2023-12-01', wage: 999),
          entry(date: '2024-05-12', wage: 100),
          entry(date: '2025-01-01', wage: 999),
        ],
        payments: [payment(date: '2023-01-01', amount: 999)],
        from: farvardin,
        to: khordad,
      );
      expect(
        series.fold<int>(0, (sum, point) => sum + point.wageRial),
        100,
      );
      expect(
        series.fold<int>(0, (sum, point) => sum + point.paymentsRial),
        0,
      );
    });

    test('adds wages, out of pocket and payments per month', () {
      final series = monthlySeries(
        entries: [
          entry(date: '2024-03-21', wage: 1000, outOfPocket: 100),
          entry(date: '2024-03-22', wage: 500),
        ],
        payments: [
          payment(date: '2024-03-25', amount: 400),
          payment(date: '2024-04-20', amount: 200),
        ],
        from: farvardin,
        to: khordad,
      );

      expect(series[0].wageRial, 1500);
      expect(series[0].outOfPocketRial, 100);
      expect(series[0].earnedRial, 1600);
      expect(series[0].paymentsRial, 400);
      expect(series[0].balanceRial, 1200);
      expect(series[0].entryCount, 2);
      expect(series[0].dayCount, 2);

      expect(series[1].paymentsRial, 200);
      expect(series[1].entryCount, 0);
      expect(series[1].balanceRial, -200);
      expect(series[1].isEmpty, isFalse);
    });

    test('counts distinct days, hours and pending wages', () {
      final series = monthlySeries(
        entries: [
          entry(date: '2024-03-21', start: '08:00', end: '12:00', wage: 100),
          entry(date: '2024-03-21', start: '22:00', end: '02:00'),
          entry(date: '2024-03-23', start: '09:00', end: '10:30', wage: 50),
        ],
        payments: const [],
        from: farvardin,
        to: khordad,
      );

      expect(series[0].dayCount, 2);
      expect(series[0].entryCount, 3);
      expect(series[0].pendingCount, 1);
      expect(series[0].hours, const Duration(hours: 9, minutes: 30));
      expect(series[0].wageRial, 150);
    });

    test('a single month range returns one point', () {
      final series = monthlySeries(
        entries: const [],
        payments: const [],
        from: farvardin,
        to: farvardin,
      );
      expect(series, hasLength(1));
      expect(series.single.month, farvardin);
    });

    test('crossing a jalali year keeps month order', () {
      final series = monthlySeries(
        entries: const [],
        payments: const [],
        from: jalaliToDateTime(1403, 11, 1),
        to: jalaliToDateTime(1404, 2, 1),
      );
      expect(series, hasLength(4));
      expect(
        series.map((p) => p.monthKey),
        [
          toIsoDate(jalaliToDateTime(1403, 11, 1)),
          toIsoDate(jalaliToDateTime(1403, 12, 1)),
          toIsoDate(jalaliToDateTime(1404, 1, 1)),
          toIsoDate(jalaliToDateTime(1404, 2, 1)),
        ],
      );
    });

    test('an inverted range returns nothing', () {
      final series = monthlySeries(
        entries: const [],
        payments: const [],
        from: khordad,
        to: farvardin,
      );
      expect(series, isEmpty);
    });
  });

  group('ledgersByEmployer', () {
    test('groups by employer and sorts by earnings', () {
      final ledgers = ledgersByEmployer(
        entries: [
          entry(employerId: 1, date: '2024-03-21', wage: 100),
          entry(employerId: 2, date: '2024-03-21', wage: 900),
          entry(employerId: 1, date: '2024-03-22', outOfPocket: 50),
        ],
        payments: [payment(employerId: 1, date: '2024-03-25', amount: 30)],
      );

      expect(ledgers.map((l) => l.employerId), [2, 1]);
      expect(ledgers[0].totals.earnedRial, 900);
      expect(ledgers[1].totals.earnedRial, 150);
      expect(ledgers[1].totals.paymentsTotalRial, 30);
      expect(ledgers[1].totals.balanceRial, 120);
      expect(ledgers[1].totals.state, SettlementState.creditor);
    });

    test('an employer with only payments still appears', () {
      final ledgers = ledgersByEmployer(
        entries: const [],
        payments: [payment(employerId: 7, date: '2024-03-25', amount: 500)],
      );
      expect(ledgers, hasLength(1));
      expect(ledgers.single.employerId, 7);
      expect(ledgers.single.totals.balanceRial, -500);
      expect(ledgers.single.totals.state, SettlementState.debtor);
    });

    test('nothing to report gives an empty list', () {
      expect(
        ledgersByEmployer(entries: const [], payments: const []),
        isEmpty,
      );
    });
  });
}
