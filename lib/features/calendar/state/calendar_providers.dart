import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/allocation.dart';
import '../../employers/state/employer_providers.dart';
import '../../payments/state/payment_providers.dart';

class VisibleMonth extends Notifier<DateTime> {
  @override
  DateTime build() => firstDayOfJalaliMonth(DateTime.now());

  void next() => state = nextJalaliMonth(state);

  void previous() => state = previousJalaliMonth(state);

  void goTo(DateTime anyDayInMonth) =>
      state = firstDayOfJalaliMonth(anyDayInMonth);

  void goToToday() => state = firstDayOfJalaliMonth(DateTime.now());
}

final visibleMonthProvider = NotifierProvider<VisibleMonth, DateTime>(
  VisibleMonth.new,
);

final monthEntriesProvider = StreamProvider.autoDispose
    .family<List<WorkEntry>, String>((ref, monthKey) {
      final start = DateTime.parse(monthKey);
      return ref
          .watch(workEntryDaoProvider)
          .watchRange(monthKey, toIsoDate(nextJalaliMonth(start)));
    });

final dayEntriesProvider = StreamProvider.autoDispose.family<List<WorkEntry>, String>(
  (ref, isoDate) => ref.watch(workEntryDaoProvider).watchForDate(isoDate),
);

final quickPlacesProvider = StreamProvider.autoDispose<List<String>>(
  (ref) => ref.watch(workEntryDaoProvider).watchDistinctPlaces(),
);

final quickJobsProvider = StreamProvider.autoDispose<List<String>>(
  (ref) => ref.watch(workEntryDaoProvider).watchDistinctJobs(),
);

/// Employer colours per Jalali day, in order of first appearance.
final monthDayColorsProvider = Provider.autoDispose
    .family<Map<String, List<int>>, String>((ref, monthKey) {
      final entries =
          ref.watch(monthEntriesProvider(monthKey)).value ?? const <WorkEntry>[];
      final employers = ref.watch(employersByIdProvider);
      final result = <String, List<int>>{};
      for (final entry in entries) {
        final color = employers[entry.employerId]?.color;
        if (color == null) continue;
        final colors = result.putIfAbsent(entry.date, () => <int>[]);
        if (!colors.contains(color)) colors.add(color);
      }
      return result;
    });

/// Days of a month that still have a pending (uncovered) workday.
final monthPendingDaysProvider = Provider.autoDispose
    .family<Set<String>, String>((ref, monthKey) {
      final entries =
          ref.watch(monthEntriesProvider(monthKey)).value ?? const <WorkEntry>[];
      final allocations = ref.watch(allocationByEmployerProvider);
      return {
        for (final entry in entries)
          if (!entryIsPaid(
            entry,
            allocations[entry.employerId] ?? const AllocationResult.none(),
          ))
            entry.date,
      };
    });
