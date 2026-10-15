import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/work_entry_dao.dart';
import '../../../domain/enums.dart';
import '../../../domain/settlement.dart';
import '../../employers/state/employer_providers.dart';

class PaymentsFilter {
  const PaymentsFilter({this.employerId, this.type});

  final int? employerId;
  final PaymentType? type;

  bool get isActive => employerId != null || type != null;

  PaymentsFilter copyWith({
    int? employerId,
    PaymentType? type,
    bool clearEmployer = false,
    bool clearType = false,
  }) {
    return PaymentsFilter(
      employerId: clearEmployer ? null : (employerId ?? this.employerId),
      type: clearType ? null : (type ?? this.type),
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
  return payments.where((payment) {
    if (filter.employerId != null && payment.employerId != filter.employerId) {
      return false;
    }
    if (filter.type != null &&
        PaymentType.fromName(payment.type) != filter.type) {
      return false;
    }
    return true;
  }).toList();
});

final filteredPaymentsTotalProvider = Provider<int>((ref) {
  final payments = ref.watch(filteredPaymentsProvider);
  return payments.fold(0, (sum, payment) => sum + payment.amount);
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
