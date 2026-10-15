import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/settlement.dart';
import '../../../domain/stats.dart';

enum StatsRangePreset {
  thisMonth('این ماه', 1),
  last3Months('۳ ماه اخیر', 3),
  last6Months('۶ ماه اخیر', 6),
  last12Months('۱۲ ماه اخیر', 12),
  thisYear('امسال', 0),
  all('از ابتدا', 0);

  const StatsRangePreset(this.label, this.months);

  final String label;
  final int months;
}

class StatsFilter {
  const StatsFilter({
    required this.from,
    required this.to,
    this.employerId,
    this.preset = StatsRangePreset.last6Months,
  });

  factory StatsFilter.initial() {
    final to = firstDayOfJalaliMonth(DateTime.now());
    return StatsFilter(
      from: toJalali(to).addMonths(-5).withDay(1).toDateTime(),
      to: to,
    );
  }

  /// First day of the first Jalali month in the range.
  final DateTime from;

  /// First day of the last Jalali month in the range.
  final DateTime to;

  final int? employerId;
  final StatsRangePreset preset;

  String get fromIso => toIsoDate(from);

  /// Exclusive upper bound that includes the whole [to] month.
  String get toIsoExclusive => toIsoDate(nextJalaliMonth(to));

  int get monthCount => jalaliMonthDistance(from, to) + 1;

  StatsFilter copyWith({
    DateTime? from,
    DateTime? to,
    int? employerId,
    StatsRangePreset? preset,
    bool clearEmployer = false,
  }) {
    return StatsFilter(
      from: from ?? this.from,
      to: to ?? this.to,
      employerId: clearEmployer ? null : (employerId ?? this.employerId),
      preset: preset ?? this.preset,
    );
  }
}

class StatsFilterController extends Notifier<StatsFilter> {
  @override
  StatsFilter build() => StatsFilter.initial();

  void setEmployer(int? employerId) => state = employerId == null
      ? state.copyWith(clearEmployer: true)
      : state.copyWith(employerId: employerId);

  void setPreset(StatsRangePreset preset) {
    final nowMonth = firstDayOfJalaliMonth(DateTime.now());
    switch (preset) {
      case StatsRangePreset.all:
        final earliest = tryParseIsoDate(
          ref.read(earliestActivityProvider).value,
        );
        final from = earliest == null
            ? nowMonth
            : firstDayOfJalaliMonth(earliest);
        state = state.copyWith(from: from, to: nowMonth, preset: preset);
      case StatsRangePreset.thisYear:
        state = state.copyWith(
          from: firstDayOfJalaliYear(nowMonth),
          to: nowMonth,
          preset: preset,
        );
      default:
        state = state.copyWith(
          from: toJalali(nowMonth)
              .addMonths(-(preset.months - 1))
              .withDay(1)
              .toDateTime(),
          to: nowMonth,
          preset: preset,
        );
    }
  }

  void setRange(DateTime from, DateTime to) {
    final a = firstDayOfJalaliMonth(from);
    final b = firstDayOfJalaliMonth(to);
    state = state.copyWith(
      from: a.isAfter(b) ? b : a,
      to: a.isAfter(b) ? a : b,
      preset: StatsRangePreset.all,
    );
  }
}

final statsFilterProvider = NotifierProvider<StatsFilterController, StatsFilter>(
  StatsFilterController.new,
);

final statsEntriesProvider = StreamProvider.autoDispose<List<WorkEntry>>((ref) {
  final filter = ref.watch(statsFilterProvider);
  return ref
      .watch(workEntryDaoProvider)
      .watchRange(
        filter.fromIso,
        filter.toIsoExclusive,
        employerId: filter.employerId,
      );
});

final statsPaymentsProvider = StreamProvider.autoDispose<List<Payment>>((ref) {
  final filter = ref.watch(statsFilterProvider);
  return ref
      .watch(paymentDaoProvider)
      .watchRange(
        filter.fromIso,
        filter.toIsoExclusive,
        employerId: filter.employerId,
      );
});

final statsTotalsProvider = Provider.autoDispose<SettlementSummary>((ref) {
  final entries = ref.watch(statsEntriesProvider).value ?? const <WorkEntry>[];
  final payments = ref.watch(statsPaymentsProvider).value ?? const <Payment>[];
  return summarizeSettlement(entries: entries, payments: payments);
});

final statsMonthlySeriesProvider = Provider.autoDispose<List<MonthlyPoint>>((
  ref,
) {
  final filter = ref.watch(statsFilterProvider);
  final entries = ref.watch(statsEntriesProvider).value ?? const <WorkEntry>[];
  final payments = ref.watch(statsPaymentsProvider).value ?? const <Payment>[];
  return monthlySeries(
    entries: entries,
    payments: payments,
    from: filter.from,
    to: filter.to,
  );
});

final statsEmployerLedgersProvider =
    Provider.autoDispose<List<EmployerLedger>>((ref) {
      final entries =
          ref.watch(statsEntriesProvider).value ?? const <WorkEntry>[];
      final payments =
          ref.watch(statsPaymentsProvider).value ?? const <Payment>[];
      return ledgersByEmployer(entries: entries, payments: payments);
    });
