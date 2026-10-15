import 'package:dipi/core/utils/time_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('clock encode and decode', () {
    test('round trips a time of day', () {
      const time = TimeOfDay(hour: 8, minute: 5);
      expect(encodeClock(time), '08:05');
      expect(decodeClock('08:05'), time);
    });

    test('rejects invalid values', () {
      expect(decodeClock(null), isNull);
      expect(decodeClock(''), isNull);
      expect(decodeClock('25:00'), isNull);
      expect(decodeClock('12:75'), isNull);
      expect(decodeClock('abc'), isNull);
    });
  });

  group('shift duration', () {
    test('simple same day shift', () {
      expect(shiftDuration('08:00', '16:30'), const Duration(hours: 8, minutes: 30));
    });

    test('shift crossing midnight', () {
      expect(shiftDuration('22:00', '06:00'), const Duration(hours: 8));
      expect(shiftDuration('23:30', '00:30'), const Duration(hours: 1));
    });

    test('missing values give null', () {
      expect(shiftDuration(null, '16:00'), isNull);
      expect(shiftDuration('08:00', null), isNull);
    });

    test('equal times give null', () {
      expect(shiftDuration('08:00', '08:00'), isNull);
    });
  });

  group('duration formatting', () {
    test('persian text', () {
      expect(formatDuration(const Duration(hours: 8, minutes: 30)), '۸ ساعت و ۳۰ دقیقه');
      expect(formatDuration(const Duration(hours: 2)), '۲ ساعت');
      expect(formatDuration(const Duration(minutes: 45)), '۴۵ دقیقه');
      expect(formatDuration(null), '—');
    });

    test('decimal hours', () {
      expect(durationHours(const Duration(hours: 1, minutes: 30)), 1.5);
      expect(formatHours(const Duration(hours: 1, minutes: 30)), '۱٫۵');
    });
  });
}
