import 'package:flutter/material.dart';

import 'persian_digits.dart';

String encodeClock(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

TimeOfDay? decodeClock(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

int? clockMinutes(String? value) {
  final time = decodeClock(value);
  if (time == null) return null;
  return time.hour * 60 + time.minute;
}

Duration? shiftDuration(String? startTime, String? endTime) {
  final start = clockMinutes(startTime);
  final end = clockMinutes(endTime);
  if (start == null || end == null) return null;
  var minutes = end - start;
  if (minutes <= 0) minutes += 24 * 60;
  if (minutes == 24 * 60 && start == end) return null;
  return Duration(minutes: minutes);
}

String formatDuration(Duration? duration) {
  if (duration == null || duration.inMinutes == 0) return '—';
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (hours == 0) return '${toPersianDigits(minutes)} دقیقه';
  if (minutes == 0) return '${toPersianDigits(hours)} ساعت';
  return '${toPersianDigits(hours)} ساعت و ${toPersianDigits(minutes)} دقیقه';
}

double durationHours(Duration? duration) =>
    duration == null ? 0 : duration.inMinutes / 60;

String formatHours(Duration? duration) => toPersianDigits(
  durationHours(duration).toStringAsFixed(1),
).replaceAll('.', '٫');

String formatClockText(String? value, {String fallback = '—'}) {
  final time = decodeClock(value);
  if (time == null) return fallback;
  return toPersianDigits(
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
  );
}
