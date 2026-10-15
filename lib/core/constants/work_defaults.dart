import 'package:flutter/material.dart';

/// Default values for a brand-new workday. Change them here only.
abstract final class WorkDefaults {
  /// Prefilled when a new workday is created (not when editing).
  static const TimeOfDay startTime = TimeOfDay(hour: 8, minute: 0);
  static const TimeOfDay endTime = TimeOfDay(hour: 17, minute: 0);

  static const String timeHint = 'ساعت‌ها را در صورت نیاز تغییر بده';
}
