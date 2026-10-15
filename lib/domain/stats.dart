import '../core/utils/jalali_utils.dart';
import '../core/utils/time_utils.dart';
import '../data/db/app_database.dart';
import 'settlement.dart';

/// One month of the activity series that backs the stats chart.
class MonthlyPoint {
  const MonthlyPoint({
    required this.month,
    required this.wageRial,
    required this.outOfPocketRial,
    required this.paymentsRial,
    required this.entryCount,
    required this.dayCount,
    required this.hours,
    required this.pendingCount,
  });

  /// First day of the Jalali month.
  final DateTime month;
  final int wageRial;
  final int outOfPocketRial;
  final int paymentsRial;
  final int entryCount;
  final int dayCount;
  final Duration hours;
  final int pendingCount;

  int get earnedRial => wageRial + outOfPocketRial;

  int get balanceRial => earnedRial - paymentsRial;

  bool get isEmpty => entryCount == 0 && paymentsRial == 0;

  String get monthKey => jalaliMonthKey(month);
}

/// One Jalali month per entry, from [from] to [to] inclusive. Months with no
/// activity are kept so the chart has an even time axis.
List<MonthlyPoint> monthlySeries({
  required Iterable<WorkEntry> entries,
  required Iterable<Payment> payments,
  required DateTime from,
  required DateTime to,
}) {
  final months = jalaliMonthsBetween(from, to);
  if (months.isEmpty) return const [];

  final buckets = <String, _MonthAccumulator>{
    for (final month in months)
      jalaliMonthKey(month): _MonthAccumulator(month),
  };

  for (final entry in entries) {
    final date = tryParseIsoDate(entry.date);
    if (date == null) continue;
    final bucket = buckets[jalaliMonthKey(date)];
    if (bucket == null) continue;
    bucket.addEntry(entry);
  }

  for (final payment in payments) {
    final date = tryParseIsoDate(payment.date);
    if (date == null) continue;
    final bucket = buckets[jalaliMonthKey(date)];
    if (bucket == null) continue;
    bucket.addPayment(payment);
  }

  return [for (final month in months) buckets[jalaliMonthKey(month)]!.build()];
}

class _MonthAccumulator {
  _MonthAccumulator(this.month);

  final DateTime month;
  int wageRial = 0;
  int outOfPocketRial = 0;
  int paymentsRial = 0;
  int entryCount = 0;
  int pendingCount = 0;
  int minutes = 0;
  final Set<String> days = {};

  void addEntry(WorkEntry entry) {
    entryCount++;
    days.add(entry.date);
    outOfPocketRial += entry.outOfPocketAmount;
    final wage = entry.wageAmount;
    if (wage == null) {
      pendingCount++;
    } else {
      wageRial += wage;
    }
    minutes += shiftDuration(entry.startTime, entry.endTime)?.inMinutes ?? 0;
  }

  void addPayment(Payment payment) => paymentsRial += payment.amount;

  MonthlyPoint build() => MonthlyPoint(
    month: month,
    wageRial: wageRial,
    outOfPocketRial: outOfPocketRial,
    paymentsRial: paymentsRial,
    entryCount: entryCount,
    dayCount: days.length,
    hours: Duration(minutes: minutes),
    pendingCount: pendingCount,
  );
}

class EmployerLedger {
  const EmployerLedger({required this.employerId, required this.totals});

  final int employerId;
  final SettlementSummary totals;
}

/// Totals per employer for the filtered period, biggest earner first.
List<EmployerLedger> ledgersByEmployer({
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
  final ledgers = [
    for (final id in ids)
      EmployerLedger(
        employerId: id,
        totals: summarizeSettlement(
          entries: entriesByEmployer[id] ?? const [],
          payments: paymentsByEmployer[id] ?? const [],
        ),
      ),
  ];

  ledgers.sort((a, b) => b.totals.earnedRial.compareTo(a.totals.earnedRial));
  return ledgers;
}
