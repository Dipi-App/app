import 'package:flutter/material.dart';

import '../../../../core/utils/persian_digits.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../domain/employer_stats.dart';
import '../../../../shared/widgets/money_text.dart';

/// Compact 2×3 grid with the six shared employer numbers. Used by both the
/// employer detail screen and each row of the employers list.
class EmployerStatsGrid extends StatelessWidget {
  const EmployerStatsGrid({
    super.key,
    required this.stats,
    this.dense = false,
  });

  final EmployerStats stats;

  /// Slightly tighter text, used inside the employers list cards.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final valueStyle = (dense ? Theme.of(context).textTheme.labelMedium : null)
        ?.copyWith(fontWeight: FontWeight.w700);

    return Column(
      children: [
        Row(
          children: [
            _StatCell(
              icon: Icons.event_available_outlined,
              value: '${toPersianDigits(stats.dayCount)} روز',
              label: 'کارکرد',
              valueStyle: valueStyle,
            ),
            _StatCell(
              icon: Icons.schedule_outlined,
              value: '${formatHours(stats.hours)} ساعت',
              label: 'ساعت کار',
              valueStyle: valueStyle,
            ),
            _StatCell(
              icon: Icons.assignment_turned_in_outlined,
              value: toPersianDigits(stats.entryCount),
              label: 'روزکار',
              valueStyle: valueStyle,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCell(
              icon: Icons.payments_outlined,
              amountRial: stats.wageRial,
              label: 'جمع دستمزد',
              valueStyle: valueStyle,
            ),
            _StatCell(
              icon: Icons.account_balance_wallet_outlined,
              amountRial: stats.outOfPocketRial,
              label: 'از جیب خودم',
              valueStyle: valueStyle,
            ),
            _StatCell(
              icon: Icons.savings_outlined,
              amountRial: stats.paymentsTotalRial,
              label: 'پرداخت‌ها',
              valueStyle: valueStyle,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    this.value,
    this.amountRial,
    required this.label,
    this.valueStyle,
  });

  final IconData icon;
  final String? value;
  final int? amountRial;
  final String label;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style =
        valueStyle ??
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 3),
          SizedBox(
            height: 20,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: amountRial != null
                  ? MoneyText(amountRial: amountRial!, style: style)
                  : Text(value ?? '—', style: style),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
