import 'package:flutter/material.dart';

import '../../../../core/utils/jalali_utils.dart';
import '../../../../core/utils/persian_digits.dart';

class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.day,
    this.colors = const [],
    this.selected = false,
    this.hasPending = false,
    this.onTap,
  });

  final DateTime day;
  final List<int> colors;
  final bool selected;
  final bool hasPending;
  final VoidCallback? onTap;

  static const double _size = 38;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = isToday(day);
    final j = toJalali(day);
    final filled = colors.isNotEmpty;

    final Color? background = colors.length == 1 ? Color(colors.first) : null;
    final Gradient? gradient = colors.length > 1
        ? _splitGradient(colors)
        : null;

    final Color foreground = filled
        ? Colors.white
        : theme.colorScheme.onSurface;

    final border = selected
        ? Border.all(color: theme.colorScheme.primary, width: 2)
        : today
        ? Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.75),
            width: 1.4,
          )
        : null;

    return Semantics(
      label: '${toPersianDigits(j.day)} ${jalaliMonthNames[j.month - 1]}',
      selected: selected,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: _size * 0.72,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: background,
              gradient: gradient,
              shape: BoxShape.circle,
              border: border,
            ),
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Text(
                  toPersianDigits(j.day),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: filled || today
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
                if (hasPending)
                  Positioned(
                    bottom: -1,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: filled
                            ? Colors.white
                            : theme.colorScheme.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _splitGradient(List<int> colors) {
    final taken = colors.take(4).toList();
    if (taken.length == 1) {
      return LinearGradient(colors: [Color(taken.first), Color(taken.first)]);
    }
    final step = 1 / taken.length;
    final stops = <double>[];
    final gradientColors = <Color>[];
    for (var i = 0; i < taken.length; i++) {
      stops
        ..add(i * step)
        ..add((i + 1) * step);
      gradientColors
        ..add(Color(taken[i]))
        ..add(Color(taken[i]));
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradientColors,
      stops: stops,
    );
  }
}
