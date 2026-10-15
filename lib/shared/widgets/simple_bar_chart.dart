import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/jalali_utils.dart';
import '../../core/utils/money.dart';
import '../../domain/stats.dart';
import '../../features/settings/state/settings_providers.dart';

/// A deliberately simple bar chart: one bar per Jalali month with the amount
/// written on top. No axes, no grid, no two-series legend — just bars a
/// low-literacy user can read at a glance.
class SimpleBarChart extends ConsumerWidget {
  const SimpleBarChart({super.key, required this.points, this.height = 190});

  final List<MonthlyPoint> points;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(
      settingsControllerProvider.select(
        (settings) => settings.value?.currencyUnit ?? CurrencyUnit.toman,
      ),
    );

    final maxValue = points.fold<int>(
      0,
      (best, point) => point.earnedRial > best ? point.earnedRial : best,
    );

    // With many months, only every n-th month name is shown to avoid crowding.
    final step = (points.length / 6).ceil().clamp(1, 12);
    final barColor = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text('درآمد هر ماه', style: theme.textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < points.length; i++)
                Expanded(
                  child: _Bar(
                    point: points[i],
                    maxValue: maxValue,
                    unit: unit,
                    color: barColor,
                    showLabel: i % step == 0 || i == points.length - 1,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.point,
    required this.maxValue,
    required this.unit,
    required this.color,
    required this.showLabel,
  });

  final MonthlyPoint point;
  final int maxValue;
  final CurrencyUnit unit;
  final Color color;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = maxValue <= 0 ? 0.0 : point.earnedRial / maxValue;
    final factor = ratio <= 0 ? 0.0 : ratio.clamp(0.05, 1.0);
    final j = toJalali(point.month);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (point.earnedRial > 0)
            // Scale the amount down to the bar width instead of clipping it,
            // so the number written on the bar always stays readable.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatMoneyCompact(point.earnedRial, unit),
                maxLines: 1,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: factor,
                child: factor <= 0
                    ? const SizedBox.shrink()
                    : Container(
                        constraints: const BoxConstraints(minWidth: 8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.85),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 18,
            child: Text(
              showLabel ? jalaliMonthNames[j.month - 1] : '',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
