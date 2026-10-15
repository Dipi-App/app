import 'package:flutter/material.dart';

import '../../../../core/utils/jalali_utils.dart';
import '../../../../core/utils/persian_digits.dart';

/// One day in the month grid.
///
/// * A worked day is filled with the employer's colour (the first one).
/// * A day with more than one employer shows small coloured dots.
/// * Today gets a clear gold ring; the selected day gets a solid fill.
/// * Days with no work keep the plain surface colour.
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

  static const double _size = 36;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = isToday(day);
    final j = toJalali(day);
    final worked = colors.isNotEmpty;

    final fill = selected
        ? scheme.primary
        : (worked ? Color(colors.first) : null);
    final foreground = selected
        ? scheme.onPrimary
        : (worked ? Colors.white : scheme.onSurface);

    final Border? border = today
        ? Border.all(color: scheme.secondary, width: 2)
        : null;

    return Semantics(
      label: '${toPersianDigits(j.day)} ${jalaliMonthNames[j.month - 1]}'
          '${worked ? '، روز کاری' : ''}${today ? '، امروز' : ''}',
      selected: selected,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: _size * 0.8,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: border,
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: colors.length > 1 ? 9 : 0),
                  child: Text(
                    toPersianDigits(j.day),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: worked || today || selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if (colors.length > 1)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final color in colors.take(3))
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: Color(color),
                                shape: BoxShape.circle,
                                border: Border.all(color: scheme.surface, width: 1),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (hasPending)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: scheme.tertiary,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 1.5),
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
}
