import 'package:dipi/data/db/app_database.dart';
import 'package:dipi/domain/work_entry_stats.dart';
import 'package:flutter_test/flutter_test.dart';

WorkEntry entry({
  required String date,
  int? wage,
  int outOfPocket = 0,
  String? start,
  String? end,
}) {
  return WorkEntry(
    id: 0,
    employerId: 1,
    date: date,
    place: null,
    job: null,
    startTime: start,
    endTime: end,
    wageType: 'fixed',
    wageAmount: wage,
    outOfPocketAmount: outOfPocket,
    note: null,
    createdAt: '2024-05-12T00:00:00.000',
  );
}

void main() {
  group('summarizeEntries', () {
    test('empty input', () {
      final totals = summarizeEntries(const []);
      expect(totals.entryCount, 0);
      expect(totals.dayCount, 0);
      expect(totals.hours, Duration.zero);
      expect(totals.wageRial, 0);
      expect(totals.isEmpty, isTrue);
    });

    test('counts distinct days and sums wages', () {
      final totals = summarizeEntries([
        entry(date: '2024-05-12', wage: 5000000),
        entry(date: '2024-05-12', wage: 1000000),
        entry(date: '2024-05-13', wage: 7000000),
      ]);
      expect(totals.entryCount, 3);
      expect(totals.dayCount, 2);
      expect(totals.wageRial, 13000000);
    });

    test('pending wages are counted separately, not in the total', () {
      final totals = summarizeEntries([
        entry(date: '2024-05-12', wage: null),
        entry(date: '2024-05-12', wage: 2000000),
      ]);
      expect(totals.pendingCount, 1);
      expect(totals.wageRial, 2000000);
    });

    test('out of pocket is summed', () {
      final totals = summarizeEntries([
        entry(date: '2024-05-12', wage: 100, outOfPocket: 5000),
        entry(date: '2024-05-13', outOfPocket: 2500),
      ]);
      expect(totals.outOfPocketRial, 7500);
    });

    test('hours add up and support midnight crossing', () {
      final totals = summarizeEntries([
        entry(date: '2024-05-12', start: '08:00', end: '12:30'),
        entry(date: '2024-05-13', start: '22:00', end: '02:00'),
      ]);
      expect(totals.hours, const Duration(hours: 8, minutes: 30));
    });

    test('entries without times contribute no hours', () {
      final totals = summarizeEntries([entry(date: '2024-05-12', wage: 1)]);
      expect(totals.hours, Duration.zero);
    });
  });
}
