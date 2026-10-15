import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../core/utils/money.dart';
import '../../../data/db/app_database.dart';
import '../../employers/state/employer_providers.dart';
import '../../payments/state/payment_providers.dart';
import '../../settings/state/settings_providers.dart';
import '../domain/export_data.dart';

enum ExportRangePreset {
  thisMonth('این ماه', 1),
  last3Months('۳ ماه اخیر', 3),
  last6Months('۶ ماه اخیر', 6),
  last12Months('۱۲ ماه اخیر', 12),
  thisYear('امسال', 0),
  all('همه', 0);

  const ExportRangePreset(this.label, this.months);

  final String label;
  final int months;
}

class ExportFilter {
  const ExportFilter({
    required this.from,
    required this.to,
    required this.employerIds,
    this.format = ExportFormat.docx,
    this.preset = ExportRangePreset.last6Months,
  });

  factory ExportFilter.initial() {
    final to = dateOnly(DateTime.now());
    return ExportFilter(
      from: toJalali(firstDayOfJalaliMonth(to))
          .addMonths(-5)
          .withDay(1)
          .toDateTime(),
      to: to,
      employerIds: const {},
    );
  }

  final DateTime from;
  final DateTime to;
  final Set<int> employerIds;
  final ExportFormat format;
  final ExportRangePreset preset;

  String get fromIso => toIsoDate(from);

  String get toIsoExclusive => toIsoDate(nextJalaliMonth(to));

  bool get allEmployers => employerIds.isEmpty;

  ExportFilter copyWith({
    DateTime? from,
    DateTime? to,
    Set<int>? employerIds,
    ExportFormat? format,
    ExportRangePreset? preset,
  }) {
    return ExportFilter(
      from: from ?? this.from,
      to: to ?? this.to,
      employerIds: employerIds ?? this.employerIds,
      format: format ?? this.format,
      preset: preset ?? this.preset,
    );
  }
}

class ExportFilterController extends Notifier<ExportFilter> {
  @override
  ExportFilter build() => ExportFilter.initial();

  void setFormat(ExportFormat format) => state = state.copyWith(format: format);

  void toggleEmployer(int employerId) {
    final next = {...state.employerIds};
    if (!next.remove(employerId)) next.add(employerId);
    state = state.copyWith(employerIds: next);
  }

  void clearEmployers() => state = state.copyWith(employerIds: const {});

  void setRange(DateTime from, DateTime to) {
    final a = dateOnly(from);
    final b = dateOnly(to);
    state = state.copyWith(
      from: a.isAfter(b) ? b : a,
      to: a.isAfter(b) ? a : b,
      preset: ExportRangePreset.all,
    );
  }

  void setPreset(ExportRangePreset preset) {
    final today = dateOnly(DateTime.now());
    final monthStart = firstDayOfJalaliMonth(today);
    switch (preset) {
      case ExportRangePreset.all:
        final earliest = tryParseIsoDate(
          ref.read(earliestActivityProvider).value,
        );
        state = state.copyWith(
          from: earliest == null ? monthStart : dateOnly(earliest),
          to: today,
          preset: preset,
        );
      case ExportRangePreset.thisYear:
        state = state.copyWith(
          from: firstDayOfJalaliYear(today),
          to: today,
          preset: preset,
        );
      default:
        state = state.copyWith(
          from: toJalali(monthStart)
              .addMonths(-(preset.months - 1))
              .withDay(1)
              .toDateTime(),
          to: today,
          preset: preset,
        );
    }
  }
}

final exportFilterProvider = NotifierProvider<ExportFilterController, ExportFilter>(
  ExportFilterController.new,
);

/// Every work entry, via the same range query with a very wide window.
final allEntriesProvider = StreamProvider<List<WorkEntry>>(
  (ref) => ref
      .watch(workEntryDaoProvider)
      .watchRange('0000-01-01', '9999-12-31'),
);

final exportDataProvider = Provider.autoDispose<ExportData>((ref) {
  final filter = ref.watch(exportFilterProvider);
  final employers = ref.watch(employersProvider).value ?? const <Employer>[];
  final entries = ref.watch(allEntriesProvider).value ?? const <WorkEntry>[];
  final payments = ref.watch(allPaymentsProvider).value ?? const <Payment>[];
  final unit = ref.watch(
    settingsControllerProvider.select(
      (settings) => settings.value?.currencyUnit ?? CurrencyUnit.toman,
    ),
  );

  return buildExportData(
    employers: employers,
    entries: entries,
    payments: payments,
    from: filter.from,
    to: filter.to,
    employerIds: filter.employerIds,
    unit: unit,
  );
});
