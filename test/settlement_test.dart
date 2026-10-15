import 'package:dipi/data/db/app_database.dart';
import 'package:dipi/domain/enums.dart';
import 'package:dipi/domain/settlement.dart';
import 'package:flutter_test/flutter_test.dart';

WorkEntry entry({
  int? wage,
  int outOfPocket = 0,
  String date = '2024-05-12',
}) {
  return WorkEntry(
    id: 0,
    employerId: 1,
    date: date,
    place: null,
    job: null,
    startTime: null,
    endTime: null,
    wageType: 'fixed',
    wageAmount: wage,
    outOfPocketAmount: outOfPocket,
    note: null,
    createdAt: '2024-05-12T00:00:00.000',
  );
}

Payment payment({
  required int amount,
  PaymentType type = PaymentType.wage,
  String date = '2024-05-12',
  int employerId = 1,
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
  group('settlementStateOf', () {
    test('maps the sign to a state', () {
      expect(settlementStateOf(1), SettlementState.creditor);
      expect(settlementStateOf(-1), SettlementState.debtor);
      expect(settlementStateOf(0), SettlementState.settled);
    });
  });

  group('balance rule', () {
    test('empty employer is settled', () {
      final summary = summarizeSettlement(entries: const [], payments: const []);
      expect(summary.balanceRial, 0);
      expect(summary.state, SettlementState.settled);
      expect(summary.isEmpty, isTrue);
    });

    test('wages alone make the employer a debtor to the worker', () {
      final summary = summarizeSettlement(
        entries: [entry(wage: 5000000), entry(wage: 3000000)],
        payments: const [],
      );
      expect(summary.wageRial, 8000000);
      expect(summary.balanceRial, 8000000);
      expect(summary.state, SettlementState.creditor);
    });

    test('out of pocket is added to the balance', () {
      final summary = summarizeSettlement(
        entries: [entry(wage: 1000000), entry(outOfPocket: 250000)],
        payments: const [],
      );
      expect(summary.outOfPocketRial, 250000);
      expect(summary.earnedRial, 1250000);
      expect(summary.balanceRial, 1250000);
    });

    test('payments are subtracted', () {
      final summary = summarizeSettlement(
        entries: [entry(wage: 5000000)],
        payments: [payment(amount: 2000000), payment(amount: 500000)],
      );
      expect(summary.paymentsTotalRial, 2500000);
      expect(summary.balanceRial, 2500000);
      expect(summary.state, SettlementState.creditor);
    });

    test('a big advance flips the balance to the worker owing', () {
      final summary = summarizeSettlement(
        entries: [entry(wage: 1000000)],
        payments: [payment(amount: 3000000, type: PaymentType.advance)],
      );
      expect(summary.balanceRial, -2000000);
      expect(summary.state, SettlementState.debtor);
      expect(summary.amountOf(PaymentType.advance), 3000000);
    });

    test('exact payments settle the account', () {
      final summary = summarizeSettlement(
        entries: [entry(wage: 4000000)],
        payments: [payment(amount: 4000000)],
      );
      expect(summary.balanceRial, 0);
      expect(summary.state, SettlementState.settled);
    });

    test('pending wages are excluded but reported', () {
      final summary = summarizeSettlement(
        entries: [entry(wage: null), entry(wage: 1000000)],
        payments: const [],
      );
      expect(summary.wageRial, 1000000);
      expect(summary.pendingCount, 1);
      expect(summary.balanceRial, 1000000);
    });

    test('payments are grouped by type', () {
      final summary = summarizeSettlement(
        entries: const [],
        payments: [
          payment(amount: 100, type: PaymentType.wage),
          payment(amount: 200, type: PaymentType.wage),
          payment(amount: 50, type: PaymentType.expenseRefund),
        ],
      );
      expect(summary.amountOf(PaymentType.wage), 300);
      expect(summary.amountOf(PaymentType.advance), 0);
      expect(summary.amountOf(PaymentType.expenseRefund), 50);
      expect(summary.paymentCount, 3);
      expect(summary.state, SettlementState.debtor);
    });

    test('an unknown payment type falls back to wage', () {
      final unknown = Payment(
        id: 1,
        employerId: 1,
        date: '2024-05-12',
        amount: 100,
        type: 'nonsense',
        note: null,
        createdAt: '2024-05-12T00:00:00.000',
      );
      final summary = summarizeSettlement(
        entries: const [],
        payments: [unknown],
      );
      expect(summary.amountOf(PaymentType.wage), 100);
    });

    test('day, entry and hour totals come from the entries', () {
      final summary = summarizeSettlement(
        entries: [
          entry(wage: 100, date: '2024-05-12'),
          entry(wage: 100, date: '2024-05-12'),
          entry(wage: 100, date: '2024-05-13'),
        ],
        payments: const [],
      );
      expect(summary.entryCount, 3);
      expect(summary.dayCount, 2);
      expect(summary.isEmpty, isFalse);
    });

    test('a payment-only employer is not empty', () {
      final summary = summarizeSettlement(
        entries: const [],
        payments: [payment(amount: 500)],
      );
      expect(summary.isEmpty, isFalse);
      expect(summary.balanceRial, -500);
    });
  });
}
