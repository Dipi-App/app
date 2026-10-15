import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/jalali_utils.dart';
import '../../core/utils/money.dart';
import '../../core/utils/persian_digits.dart';
import '../../domain/enums.dart';
import '../../domain/stats.dart';
import '../../features/settings/state/settings_providers.dart';
import '../utils/motion.dart';

class MonthlyChart extends ConsumerWidget {
  const MonthlyChart({super.key, required this.points, this.height = 230});

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
    final reduced = reduceMotion(context);

    final maxValue = points.fold<int>(
      0,
      (best, point) => math.max(best, math.max(point.earnedRial, point.paymentsRial)),
    );
    final maxY = _niceCeil(maxValue.toDouble());
    final interval = maxY / 3;

    final earnedColor = AppColors.settlementColor(
      context,
      SettlementState.creditor,
    );
    final paidColor = theme.colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _LegendDot(color: earnedColor, label: 'درآمد (دستمزد + از جیب)'),
            _LegendDot(color: paidColor, label: 'دریافتی'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final count = points.isEmpty ? 1 : points.length;
              final groupWidth = constraints.maxWidth / count;
              final rodWidth = (groupWidth / 2 - 2).clamp(3.0, 14.0);
              // Keep month names from colliding: the longest name needs roughly
              // this much room, so skip labels until they fit.
              const longestLabelWidth = 58.0;
              final labelInterval = math.max(
                1.0,
                (longestLabelWidth / groupWidth).ceilToDouble(),
              );

              return BarChart(
                duration: reduced
                    ? Duration.zero
                    : const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  groupsSpace: groupWidth * 0.35,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final point = points[group.x];
                        return BarTooltipItem(
                          '${formatJalaliMonthYear(point.month)}\n'
                          '${rodIndex == 0 ? 'درآمد' : 'دریافتی'}: '
                          '${formatMoney(rod.toY.round(), unit)}',
                          theme.textTheme.bodySmall!.copyWith(
                            color: theme.colorScheme.onInverseSurface,
                          ),
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.6,
                      ),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          if (value <= 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              formatMoneyCompact(value.round(), unit),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: labelInterval,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          // Bar charts ignore the axis interval, so skip labels
                          // by hand until the month names have room.
                          if (index % labelInterval.round() != 0) {
                            return const SizedBox.shrink();
                          }
                          final point = points[index];
                          final jalali = toJalali(point.month);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  jalaliMonthNames[jalali.month - 1],
                                  softWrap: false,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (jalali.month == 1 || index == 0)
                                  Text(
                                    toPersianDigits(jalali.year),
                                    softWrap: false,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 9,
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var index = 0; index < points.length; index++)
                      BarChartGroupData(
                        x: index,
                        barsSpace: 3,
                        barRods: [
                          BarChartRodData(
                            toY: points[index].earnedRial.toDouble(),
                            color: earnedColor,
                            width: rodWidth,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                          BarChartRodData(
                            toY: points[index].paymentsRial.toDouble(),
                            color: paidColor,
                            width: rodWidth,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

double _niceCeil(double value) {
  if (value <= 0) return 1;
  final exponent = (math.log(value) / math.ln10).floor();
  final magnitude = math.pow(10, exponent).toDouble();
  for (final step in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
    if (value <= step * magnitude) return step * magnitude;
  }
  return 10 * magnitude;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
