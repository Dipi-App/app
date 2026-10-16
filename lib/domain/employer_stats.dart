import '../data/db/app_database.dart';
import 'settlement.dart';

/// The six numbers shown for one employer, in both the employer detail screen
/// and the employers list. Built from [SettlementSummary] so there is a single
/// source of truth for the arithmetic.
class EmployerStats {
  const EmployerStats({
    required this.dayCount,
    required this.entryCount,
    required this.hours,
    required this.wageRial,
    required this.outOfPocketRial,
    required this.paymentsTotalRial,
  });

  factory EmployerStats.fromSummary(SettlementSummary summary) => EmployerStats(
    dayCount: summary.dayCount,
    entryCount: summary.entryCount,
    hours: summary.hours,
    wageRial: summary.wageRial,
    outOfPocketRial: summary.outOfPocketRial,
    paymentsTotalRial: summary.paymentsTotalRial,
  );

  const EmployerStats.empty()
    : dayCount = 0,
      entryCount = 0,
      hours = Duration.zero,
      wageRial = 0,
      outOfPocketRial = 0,
      paymentsTotalRial = 0;

  final int dayCount;
  final int entryCount;
  final Duration hours;
  final int wageRial;
  final int outOfPocketRial;
  final int paymentsTotalRial;

  int get earnedRial => wageRial + outOfPocketRial;

  bool get isEmpty => entryCount == 0 && paymentsTotalRial == 0;
}

/// The shared use-case. Every screen calls this (directly or through
/// [employerStatsByEmployer]) so the numbers can never drift apart.
EmployerStats employerStats({
  required Iterable<WorkEntry> entries,
  required Iterable<Payment> payments,
}) {
  return EmployerStats.fromSummary(
    summarizeSettlement(entries: entries, payments: payments),
  );
}

/// Stats for every employer in a single pass over [entries] and [payments].
Map<int, EmployerStats> employerStatsByEmployer({
  required Iterable<WorkEntry> entries,
  required Iterable<Payment> payments,
}) {
  final entriesByEmployer = <int, List<WorkEntry>>{};
  for (final entry in entries) {
    entriesByEmployer.putIfAbsent(entry.employerId, () => []).add(entry);
  }
  final paymentsByEmployer = <int, List<Payment>>{};
  for (final payment in payments) {
    paymentsByEmployer.putIfAbsent(payment.employerId, () => []).add(payment);
  }

  final ids = {...entriesByEmployer.keys, ...paymentsByEmployer.keys};
  return {
    for (final id in ids)
      id: employerStats(
        entries: entriesByEmployer[id] ?? const [],
        payments: paymentsByEmployer[id] ?? const [],
      ),
  };
}
