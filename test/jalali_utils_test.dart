import 'package:dipi/core/utils/jalali_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Gregorian to Jalali', () {
    test('nowruz 1403', () {
      expect(formatJalaliShort(DateTime(2024, 3, 20)), '۱۴۰۳/۰۱/۰۱');
      expect(formatJalaliShort(DateTime(2024, 3, 21)), '۱۴۰۳/۰۱/۰۲');
    });

    test('mid year', () {
      expect(formatJalaliShort(DateTime(2024, 5, 12)), '۱۴۰۳/۰۲/۲۳');
      expect(formatJalaliLong(DateTime(2024, 5, 12)), '۲۳ اردیبهشت ۱۴۰۳');
    });

    test('end of year (1403 is a leap year)', () {
      expect(jalaliMonthLength(1403, 12), 30);
      expect(formatJalaliShort(DateTime(2025, 3, 20)), '۱۴۰۳/۱۲/۳۰');
      expect(formatJalaliShort(DateTime(2025, 3, 21)), '۱۴۰۴/۰۱/۰۱');
    });
  });

  group('week starts on Saturday', () {
    test('saturday is index 0', () {
      expect(persianWeekdayIndex(DateTime(2024, 3, 16)), 0);
      expect(formatJalaliWeekdayLong(DateTime(2024, 3, 16)), 'شنبه');
    });

    test('friday is index 6', () {
      expect(persianWeekdayIndex(DateTime(2024, 3, 22)), 6);
      expect(formatJalaliWeekdayLong(DateTime(2024, 3, 22)), 'جمعه');
    });

    test('wednesday is index 4', () {
      expect(persianWeekdayIndex(DateTime(2024, 3, 20)), 4);
    });
  });

  group('month grid', () {
    test('farvardin 1403 starts on wednesday with 31 days', () {
      final grid = jalaliMonthGrid(DateTime(2024, 3, 20));
      expect(grid.length % 7, 0);
      expect(grid.take(4).every((day) => day == null), isTrue);
      expect(grid[4], DateTime(2024, 3, 20));
      expect(grid.whereType<DateTime>().length, 31);
    });

    test('month navigation moves by jalali month', () {
      final next = nextJalaliMonth(DateTime(2024, 3, 20));
      expect(formatJalaliShort(next), '۱۴۰۳/۰۲/۰۱');
      final previous = previousJalaliMonth(DateTime(2024, 3, 20));
      expect(formatJalaliShort(previous), '۱۴۰۲/۱۲/۰۱');
    });
  });

  group('round trip', () {
    test('jalali to date time and back', () {
      final date = jalaliToDateTime(1403, 2, 23);
      expect(toIsoDate(date), '2024-05-12');
      final same = toJalali(date);
      expect([same.year, same.month, same.day], [1403, 2, 23]);
    });

    test('only date part is kept', () {
      expect(toIsoDate(DateTime(2024, 5, 12, 23, 59)), '2024-05-12');
    });
  });
}
