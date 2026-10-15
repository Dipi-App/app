import '../core/utils/time_utils.dart';
import '../data/db/app_database.dart';

class EntryTotals {
  const EntryTotals({
    required this.entryCount,
    required this.dayCount,
    required this.hours,
    required this.wageRial,
    required this.outOfPocketRial,
    required this.pendingCount,
  });

  const EntryTotals.empty()
    : entryCount = 0,
      dayCount = 0,
      hours = Duration.zero,
      wageRial = 0,
      outOfPocketRial = 0,
      pendingCount = 0;

  final int entryCount;
  final int dayCount;
  final Duration hours;
  final int wageRial;
  final int outOfPocketRial;

  /// Entries whose wage amount is not known yet. They are not counted in
  /// [wageRial] until the user fills a value in.
  final int pendingCount;

  bool get isEmpty => entryCount == 0;
}

EntryTotals summarizeEntries(Iterable<WorkEntry> entries) {
  var entryCount = 0;
  var wageRial = 0;
  var outOfPocketRial = 0;
  var pendingCount = 0;
  var minutes = 0;
  final days = <String>{};

  for (final entry in entries) {
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

  return EntryTotals(
    entryCount: entryCount,
    dayCount: days.length,
    hours: Duration(minutes: minutes),
    wageRial: wageRial,
    outOfPocketRial: outOfPocketRial,
    pendingCount: pendingCount,
  );
}
