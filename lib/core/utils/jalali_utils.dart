import 'package:shamsi_date/shamsi_date.dart';

import 'persian_digits.dart';

const List<String> jalaliMonthNames = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

const List<String> jalaliWeekdayNames = [
  'شنبه',
  'یک‌شنبه',
  'دوشنبه',
  'سه‌شنبه',
  'چهارشنبه',
  'پنج‌شنبه',
  'جمعه',
];

const List<String> jalaliWeekdayShort = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

String toIsoDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime? tryParseIsoDate(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  return DateTime.tryParse(iso);
}

int persianWeekdayIndex(DateTime date) => Jalali.fromDateTime(date).weekDay - 1;

Jalali toJalali(DateTime date) => Jalali.fromDateTime(date);

DateTime jalaliToDateTime(int year, int month, int day) =>
    Jalali(year, month, day).toDateTime();

String formatJalaliShort(DateTime date) {
  final j = toJalali(date);
  return toPersianDigits(
    '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}',
  );
}

String formatJalaliShortIso(String? iso) {
  final date = tryParseIsoDate(iso);
  return date == null ? '—' : formatJalaliShort(date);
}

String formatJalaliLongIso(String? iso) {
  final date = tryParseIsoDate(iso);
  return date == null ? '—' : formatJalaliLong(date);
}

String formatJalaliLong(DateTime date) {
  final j = toJalali(date);
  return toPersianDigits('${j.day} ${jalaliMonthNames[j.month - 1]} ${j.year}');
}

String formatJalaliMonthYear(DateTime date) {
  final j = toJalali(date);
  return toPersianDigits('${jalaliMonthNames[j.month - 1]} ${j.year}');
}

String formatJalaliWeekdayLong(DateTime date) =>
    jalaliWeekdayNames[persianWeekdayIndex(date)];

String formatJalaliFullLong(DateTime date) =>
    '${formatJalaliWeekdayLong(date)}، ${formatJalaliLong(date)}';

int jalaliMonthLength(int year, int month) => Jalali(year, month).monthLength;

DateTime firstDayOfJalaliMonth(DateTime anyDayInMonth) {
  final j = toJalali(anyDayInMonth);
  return Jalali(j.year, j.month, 1).toDateTime();
}

DateTime firstDayOfJalaliYear(DateTime anyDayInYear) {
  final j = toJalali(anyDayInYear);
  return Jalali(j.year, 1, 1).toDateTime();
}

/// Canonical key for a Jalali month: the ISO date of its first day.
String jalaliMonthKey(DateTime day) => toIsoDate(firstDayOfJalaliMonth(day));

/// Every Jalali month from [from] to [to], both inclusive.
List<DateTime> jalaliMonthsBetween(DateTime from, DateTime to) {
  final first = firstDayOfJalaliMonth(from);
  final last = firstDayOfJalaliMonth(to);
  final months = <DateTime>[];
  var cursor = first;
  while (!cursor.isAfter(last)) {
    months.add(cursor);
    cursor = nextJalaliMonth(cursor);
  }
  return months;
}

int jalaliMonthDistance(DateTime from, DateTime to) {
  final a = toJalali(from);
  final b = toJalali(to);
  return (b.year - a.year) * 12 + (b.month - a.month);
}

DateTime nextJalaliMonth(DateTime anyDayInMonth) {
  final j = toJalali(anyDayInMonth);
  return j.addMonths(1).withDay(1).toDateTime();
}

DateTime previousJalaliMonth(DateTime anyDayInMonth) {
  final j = toJalali(anyDayInMonth);
  return j.addMonths(-1).withDay(1).toDateTime();
}

List<DateTime?> jalaliMonthGrid(DateTime anyDayInMonth) {
  final j = toJalali(anyDayInMonth);
  final first = Jalali(j.year, j.month, 1);
  final length = first.monthLength;
  final leading = first.weekDay - 1;
  final cells = <DateTime?>[];
  for (var i = 0; i < leading; i++) {
    cells.add(null);
  }
  for (var day = 1; day <= length; day++) {
    cells.add(Jalali(j.year, j.month, day).toDateTime());
  }
  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return cells;
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isToday(DateTime date) => isSameDay(date, DateTime.now());
