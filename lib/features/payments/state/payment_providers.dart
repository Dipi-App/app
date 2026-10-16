import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/allocation.dart';
import '../../../domain/employer_stats.dart';
import '../../../domain/enums.dart';
import '../../../domain/settlement.dart';
import '../../../domain/stats.dart';
import '../../employers/state/employer_providers.dart';

class PaymentsFilter {
  const PaymentsFilter({this.employerId, this.type, this.from, this.to});

  final int? employerId;
  final PaymentType? type;
  final DateTime? from;
  final DateTime? to;

  bool get hasRange => from != null || to != null;

  bool get isActive =>
      employerId != null || type != null || from != null || to != null;

  PaymentsFilter copyWith({
    int? employerId,
    PaymentType? type,
    DateTime? from,
    DateTime? to,
    bool clearEmployer = false,
    bool clearType = false,
    bool clearRange = false,
  }) {
    return PaymentsFilter(
      employerId: clearEmployer ? null : (employerId ?? this.employerId),
      type: clearType ? null : (type ?? this.type),
      from: clearRange ? null : (from ?? this.from),
      to: clearRange ? null : (to ?? this.to),
    );
  }
}

class PaymentsFilterController extends Notifier<PaymentsFilter> {
  @override
  PaymentsFilter build() => const PaymentsFilter();

  void setEmployer(int? employerId) => state = employerId == null
      ? state.copyWith(clearEmployer: true)
      : state.copyWith(employerId: employerId);

  void setType(PaymentType? type) => state = type == null
      ? state.copyWith(clearType: true)
      : state.copyWith(type: type);

  void setRange(DateTime from, DateTime to) {
    state = state.copyWith(
      from: from.isAfter(to) ? to : from,
      to: from.isAfter(to) ? from : to,
    );
  }

  void clearRange() => state = state.copyWith(clearRange: true);

  void clear() => state = const PaymentsFilter();
}

final paymentsFilterProvider =
    NotifierProvider<PaymentsFilterController, PaymentsFilter>(
      PaymentsFilterController.new,
    );

final allPaymentsProvider = StreamProvider<List<Payment>>(
  (ref) => ref.watch(paymentDaoProvider).watchAll(),
);

final filteredPaymentsProvider = Provider<List<Payment>>((ref) {
  final payments = ref.watch(allPaymentsProvider).value ?? const <Payment>[];
  final filter = ref.watch(paymentsFilterProvider);
  final fromIso = filter.from == null ? null : toIsoDate(filter.from!);
  final toIso = filter.to == null ? null : toIsoDate(filter.to!);
  return payments.where((payment) {
    if (filter.employerId != null && payment.employerId != filter.employerId) {
      return false;
    }
    if (filter.type != null &&
        PaymentType.fromName(payment.type) != filter.type) {
      return false;
    }
    if (fromIso != null && payment.date.compareTo(fromIso) < 0) return false;
    if (toIso != null && payment.date.compareTo(toIso) > 0) return false;
    return true;
  }).toList();
});

final filteredPaymentsTotalProvider = Provider<int>((ref) {
  final payments = ref.watch(filteredPaymentsProvider);
  return payments.fold(0, (sum, payment) => sum + payment.amount);
});

/// One Jalali month of payments, newest month first.
class PaymentMonthGroup {
  const PaymentMonthGroup({required this.month, required this.payments});

  final DateTime month;
  final List<Payment> payments;

  int get totalRial =>
      payments.fold(0, (sum, payment) => sum + payment.amount);
}

final filteredPaymentGroupsProvider = Provider<List<PaymentMonthGroup>>((ref) {
  final payments = ref.watch(filteredPaymentsProvider);
  final byMonth = <String, List<Payment>>{};
  final monthByKey = <String, DateTime>{};
  for (final payment in payments) {
    final date = tryParseIsoDate(payment.date);
    if (date == null) continue;
    final key = jalaliMonthKey(date);
    monthByKey[key] = firstDayOfJalaliMonth(date);
    byMonth.putIfAbsent(key, () => <Payment>[]).add(payment);
  }
  final keys = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final key in keys)
      PaymentMonthGroup(month: monthByKey[key]!, payments: byMonth[key]!),
  ];
});

final employerPaymentsProvider = StreamProvider.family<List<Payment>, int>(
  (ref, employerId) => ref.watch(paymentDaoProvider).watchForEmployer(employerId),
);

/// Every work entry in the ledger, loaded once so the derived per-employer
/// numbers need no query per card.
final allWorkEntriesProvider = StreamProvider<List<WorkEntry>>(
  (ref) => ref.watch(workEntryDaoProvider).watchAll(),
);

/// Derived payment allocation per employer. Computed, never saved, so editing
/// or deleting a payment updates it by itself.
final allocationByEmployerProvider = Provider<Map<int, AllocationResult>>((
  ref,
) {
  final entries =
      ref.watch(allWorkEntriesProvider).value ?? const <WorkEntry>[];
  final payments = ref.watch(allPaymentsProvider).value ?? const <Payment>[];
  final employers = ref.watch(employersByIdProvider);

  final entriesByEmployer = <int, List<WorkEntry>>{};
  for (final entry in entries) {
    entriesByEmployer.putIfAbsent(entry.employerId, () => []).add(entry);
  }
  final paymentsByEmployer = <int, List<Payment>>{};
  for (final payment in payments) {
    paymentsByEmployer.putIfAbsent(payment.employerId, () => []).add(payment);
  }

  return {
    for (final employer in employers.values)
      employer.id: allocateEmployer(
        dailyWageRial: employer.defaultDailyWage,
        entries: entriesByEmployer[employer.id] ?? const <WorkEntry>[],
        payments: paymentsByEmployer[employer.id] ?? const <Payment>[],
      ),
  };
});

final employerAllocationProvider = Provider.family<AllocationResult, int>(
  (ref, employerId) =>
      ref.watch(allocationByEmployerProvider)[employerId] ??
      const AllocationResult.none(),
);

/// The six shared stats for every employer, computed in a single pass.
final employerStatsMapProvider = Provider<Map<int, EmployerStats>>((ref) {
  final entries =
      ref.watch(allWorkEntriesProvider).value ?? const <WorkEntry>[];
  final payments = ref.watch(allPaymentsProvider).value ?? const <Payment>[];
  return employerStatsByEmployer(entries: entries, payments: payments);
});

/// Balance per employer.
///
/// With a daily wage defined the balance follows the payment allocation:
/// `uncovered pending days × W − credit`. Without one the classic rule is
/// kept: `earned − payments`.
final employerBalancesProvider = Provider<Map<int, int>>((ref) {
  final employers = ref.watch(employersByIdProvider);
  final allocations = ref.watch(allocationByEmployerProvider);
  final stats = ref.watch(employerStatsMapProvider);
  final result = <int, int>{};
  for (final employer in employers.values) {
    final wage = employer.defaultDailyWage;
    if (wage != null && wage > 0) {
      final allocation =
          allocations[employer.id] ?? const AllocationResult.none();
      result[employer.id] = allocation.balanceRial(wage);
    } else {
      final stat = stats[employer.id] ?? const EmployerStats.empty();
      result[employer.id] = stat.wageRial + stat.outOfPocketRial - stat.paymentsTotalRial;
    }
  }
  return result;
});

/// Positive means employers owe the worker overall.
final overallBalanceProvider = Provider<int>((ref) {
  return ref
      .watch(employerBalancesProvider)
      .values
      .fold(0, (sum, balance) => sum + balance);
});

final employerBalanceProvider = Provider.family<int, int>(
  (ref, employerId) => ref.watch(employerBalancesProvider)[employerId] ?? 0,
);

final employerSettlementProvider = Provider.family<SettlementSummary, int>((
  ref,
  employerId,
) {
  final entries =
      ref.watch(employerEntriesProvider(employerId)).value ??
      const <WorkEntry>[];
  final payments =
      ref.watch(employerPaymentsProvider(employerId)).value ??
      const <Payment>[];
  return summarizeSettlement(entries: entries, payments: payments);
});

/// The last 12 Jalali months for one employer, for the settlement chart.
final employerMonthlySeriesProvider =
    Provider.family<List<MonthlyPoint>, int>((ref, employerId) {
      final to = firstDayOfJalaliMonth(DateTime.now());
      final from = toJalali(to).addMonths(-11).withDay(1).toDateTime();
      final entries =
          ref.watch(employerEntriesProvider(employerId)).value ??
          const <WorkEntry>[];
      final payments =
          ref.watch(employerPaymentsProvider(employerId)).value ??
          const <Payment>[];
      return monthlySeries(
        entries: entries,
        payments: payments,
        from: from,
        to: to,
      );
    });
