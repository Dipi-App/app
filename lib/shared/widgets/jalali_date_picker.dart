import 'package:flutter/material.dart';

import '../../core/utils/jalali_utils.dart';
import '../../core/utils/persian_digits.dart';
import '../../core/widgets/directional_icons.dart';

Future<DateTime?> showJalaliDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => _JalaliDatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

class _JalaliDatePickerDialog extends StatefulWidget {
  const _JalaliDatePickerDialog({
    required this.initialDate,
    this.firstDate,
    this.lastDate,
  });

  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  State<_JalaliDatePickerDialog> createState() =>
      _JalaliDatePickerDialogState();
}

class _JalaliDatePickerDialogState extends State<_JalaliDatePickerDialog> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = dateOnly(widget.initialDate);
    _month = firstDayOfJalaliMonth(_selected);
  }

  bool _isSelectable(DateTime day) {
    if (widget.firstDate != null && day.isBefore(dateOnly(widget.firstDate!))) {
      return false;
    }
    if (widget.lastDate != null && day.isAfter(dateOnly(widget.lastDate!))) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cells = jalaliMonthGrid(_month);

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      title: const Text('انتخاب تاریخ'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () =>
                      setState(() => _month = previousJalaliMonth(_month)),
                  icon: const Icon(DirectionalIcons.back),
                  tooltip: 'ماه قبل',
                ),
                Expanded(
                  child: Text(
                    formatJalaliMonthYear(_month),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      setState(() => _month = nextJalaliMonth(_month)),
                  icon: const Icon(DirectionalIcons.forward),
                  tooltip: 'ماه بعد',
                ),
              ],
            ),
            Row(
              children: [
                for (final label in jalaliWeekdayShort)
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            for (var row = 0; row < cells.length ~/ 7; row++)
              Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: _DayButton(
                        day: cells[row * 7 + col],
                        selected: cells[row * 7 + col] != null &&
                            isSameDay(cells[row * 7 + col]!, _selected),
                        enabled: cells[row * 7 + col] != null &&
                            _isSelectable(cells[row * 7 + col]!),
                        onTap: (day) => setState(() {
                          _selected = day;
                          _month = firstDayOfJalaliMonth(day);
                        }),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('انصراف'),
        ),
        TextButton(
          onPressed: () {
            final today = dateOnly(DateTime.now());
            if (_isSelectable(today)) {
              setState(() {
                _selected = today;
                _month = firstDayOfJalaliMonth(today);
              });
            }
          },
          child: const Text('امروز'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('تأیید'),
        ),
      ],
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.day,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final DateTime? day;
  final bool selected;
  final bool enabled;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = day;
    if (value == null) return const SizedBox(height: 40);

    final j = toJalali(value);
    final today = isToday(value);

    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: selected
              ? theme.colorScheme.primary
              : today
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: enabled ? () => onTap(value) : null,
            child: Center(
              child: Text(
                toPersianDigits(j.day),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: !enabled
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                      : selected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
