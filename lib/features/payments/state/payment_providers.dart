import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/work_entry_dao.dart';
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

/// Wage and out-of-pocket sums per employer (aggregated in SQLite).
final entrySumsProvider = StreamProvider<Map<int, EntrySums>>(
  (ref) => ref.watch(workEntryDaoProvider).watchSumsByEmployer(),
);

/// Total paid per employer (aggregated in SQLite).
final paymentSumsProvider = StreamProvider<Map<int, int>>(
  (ref) => ref.watch(paymentDaoProvider).watchTotalsByEmployer(),
);

/// Balance per employer, following the balance rule.
final employerBalancesProvider = Provider<Map<int, int>>((ref) {
  final entries = ref.watch(entrySumsProvider).value ?? const <int, EntrySums>{};
  final payments =
      ref.watch(paymentSumsProvider).value ?? const <int, int>{};
  final result = <int, int>{};
  for (final employerId in {...entries.keys, ...payments.keys}) {
    final sums = entries[employerId];
    result[employerId] =
        (sums?.wageRial ?? 0) +
        (sums?.outOfPocketRial ?? 0) -
        (payments[employerId] ?? 0);
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
