import '../../../core/utils/persian_digits.dart';

/// A short file size with Persian digits, e.g. `۱۲٫۵ مگابایت`.
String formatUpdateSize(int bytes) {
  if (bytes <= 0) return 'نامعلوم';
  String oneDecimal(double value) =>
      toPersianDigits(value.toStringAsFixed(1)).replaceAll('.', '٫');
  if (bytes < 1024) return '${toPersianDigits(bytes)} بایت';
  if (bytes < 1024 * 1024) {
    return '${oneDecimal(bytes / 1024)} کیلوبایت';
  }
  return '${oneDecimal(bytes / (1024 * 1024))} مگابایت';
}

/// A whole-number percent with Persian digits, e.g. `۴۲٪`.
String formatUpdatePercent(double progress) =>
    '${toPersianDigits((progress.clamp(0, 1) * 100).floor())}٪';
