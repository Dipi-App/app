import '../data/db/app_database.dart';
import 'enums.dart';
import 'work_entry_stats.dart';

SettlementState settlementStateOf(int balanceRial) {
  if (balanceRial > 0) return SettlementState.creditor;
  if (balanceRial < 0) return SettlementState.debtor;
  return SettlementState.settled;
}

/// Balance rule for one employer in a period:
/// `balance = sum(wage_amount) + sum(out_of_pocket_amount) − sum(payments)`.
///
/// Positive → the employer owes the worker. Negative → the worker owes the
/// employer (for example after a big advance). Wages whose amount is not filled
/// in yet are reported separately and are not counted.
class SettlementSummary {
  const SettlementSummary({
    required this.entryTotals,
    required this.paymentsTotalRial,
    required this.paymentsByType,
    required this.paymentCount,
  });

  const SettlementSummary.empty()
    : entryTotals = const EntryTotals.empty(),
      paymentsTotalRial = 0,
      paymentsByType = const {},
      paymentCount = 0;

  final EntryTotals entryTotals;
  final int paymentsTotalRial;
  final Map<PaymentType, int> paymentsByType;
  final int paymentCount;

  int get wageRial => entryTotals.wageRial;

  int get outOfPocketRial => entryTotals.outOfPocketRial;

  int get earnedRial => wageRial + outOfPocketRial;

  int get balanceRial => earnedRial - paymentsTotalRial;

  int get pendingCount => entryTotals.pendingCount;

  int get dayCount => entryTotals.dayCount;

  int get entryCount => entryTotals.entryCount;

  Duration get hours => entryTotals.hours;

  SettlementState get state => settlementStateOf(balanceRial);

  int amountOf(PaymentType type) => paymentsByType[type] ?? 0;

  bool get isEmpty => entryCount == 0 && paymentCount == 0;
}

SettlementSummary summarizeSettlement({
  required Iterable<WorkEntry> entries,
  required Iterable<Payment> payments,
}) {
  final entryTotals = summarizeEntries(entries);
  var paymentsTotal = 0;
  var paymentCount = 0;
  final byType = <PaymentType, int>{};

  for (final payment in payments) {
    paymentCount++;
    paymentsTotal += payment.amount;
    final type = PaymentType.fromName(payment.type);
    byType[type] = (byType[type] ?? 0) + payment.amount;
  }

  return SettlementSummary(
    entryTotals: entryTotals,
    paymentsTotalRial: paymentsTotal,
    paymentsByType: byType,
    paymentCount: paymentCount,
  );
}

/// One row of the "who owes whom" summary across all employers.
class EmployerBalanceRow {
  const EmployerBalanceRow({
    required this.employer,
    required this.balanceRial,
  });

  final Employer employer;
  final int balanceRial;

  SettlementState get state => settlementStateOf(balanceRial);
}
