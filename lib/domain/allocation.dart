import '../data/db/app_database.dart';

/// Result of allocating an employer's payments to their pending workdays.
///
/// A workday is *pending* while it has no wage amount of its own. Payments are
/// money received from the employer; the allocation covers the oldest pending
/// days first, one daily wage (W) per day.
///
/// Nothing here is persisted: the allocation is derived from the workdays and
/// payments, so editing or deleting a payment updates it automatically.
class AllocationResult {
  const AllocationResult({
    required this.hasDailyWage,
    required this.paidDays,
    required this.pendingDays,
    required this.creditRial,
  });

  const AllocationResult.none()
    : hasDailyWage = false,
      paidDays = const {},
      pendingDays = const [],
      creditRial = 0;

  /// Whether the employer defines a daily wage. When false the caller must
  /// keep the previous behaviour (no allocation is applied).
  final bool hasDailyWage;

  /// Covered pending days: work-entry id → wage amount (W) in Rial.
  final Map<int, int> paidDays;

  /// Pending days that the payments did not cover, oldest first.
  final List<WorkEntry> pendingDays;

  /// Money received but not enough to cover another full day (or left over
  /// once every pending day is covered).
  final int creditRial;

  int get coveredCount => paidDays.length;

  int get pendingCount => pendingDays.length;

  bool isPaid(int entryId) => paidDays.containsKey(entryId);

  int? amountFor(int entryId) => paidDays[entryId];

  bool get isSettled => pendingDays.isEmpty;

  /// `uncovered pending days × W − credit`. Once every pending day is covered
  /// the account is settled: the balance is 0 and any leftover money is shown
  /// as credit. Callers must pass the same wage used in [allocate].
  int balanceRial(int dailyWageRial) {
    if (pendingDays.isEmpty) return 0;
    return pendingDays.length * dailyWageRial - creditRial;
  }
}

/// Allocates [payments] to [pendingDaysSorted] (oldest first), one
/// [dailyWageRial] per day. Pure and integer-only.
AllocationResult allocate({
  required int? dailyWageRial,
  required List<WorkEntry> pendingDaysSorted,
  required Iterable<Payment> payments,
}) {
  final wage = dailyWageRial;
  if (wage == null || wage <= 0) {
    return AllocationResult(
      hasDailyWage: false,
      paidDays: const {},
      pendingDays: pendingDaysSorted,
      creditRial: 0,
    );
  }

  var received = 0;
  for (final payment in payments) {
    received += payment.amount;
  }

  final coverable = received ~/ wage;
  final covered = coverable < pendingDaysSorted.length
      ? coverable
      : pendingDaysSorted.length;

  final paidDays = <int, int>{
    for (var i = 0; i < covered; i++) pendingDaysSorted[i].id: wage,
  };
  final credit = received - covered * wage;

  return AllocationResult(
    hasDailyWage: true,
    paidDays: paidDays,
    pendingDays: pendingDaysSorted.sublist(covered),
    creditRial: credit,
  );
}

/// Sorts pending days oldest first (by date, then by id) and allocates.
AllocationResult allocateEmployer({
  required int? dailyWageRial,
  required Iterable<WorkEntry> entries,
  required Iterable<Payment> payments,
}) {
  final pending = [
    for (final entry in entries)
      if (entry.wageAmount == null) entry,
  ]..sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  });
  return allocate(
    dailyWageRial: dailyWageRial,
    pendingDaysSorted: pending,
    payments: payments,
  );
}

/// Whether an entry is paid: either it has its own wage, or the allocation
/// covered it with the employer's daily wage.
bool entryIsPaid(WorkEntry entry, AllocationResult allocation) {
  if (entry.wageAmount != null) return true;
  return allocation.isPaid(entry.id);
}
