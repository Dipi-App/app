import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/enums.dart';
import '../../domain/settlement.dart';
import 'money_text.dart';

IconData _stateIcon(SettlementState state) => switch (state) {
  SettlementState.creditor => Icons.trending_up_rounded,
  SettlementState.debtor => Icons.trending_down_rounded,
  SettlementState.settled => Icons.check_circle_outline_rounded,
};

class BalanceChip extends StatelessWidget {
  const BalanceChip({
    super.key,
    required this.balanceRial,
    this.showAmount = true,
    this.compact = false,
  });

  final int balanceRial;
  final bool showAmount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = settlementStateOf(balanceRial);
    final color = AppColors.settlementColor(context, state);
    final theme = Theme.of(context);
    final style = (compact
            ? theme.textTheme.labelSmall
            : theme.textTheme.labelMedium)
        ?.copyWith(color: color, fontWeight: FontWeight.w700);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_stateIcon(state), size: compact ? 13 : 15, color: color),
          const SizedBox(width: 4),
          Text(state.label, style: style),
          if (showAmount) ...[
            const SizedBox(width: 6),
            MoneyText(
              amountRial: balanceRial.abs(),
              style: style,
            ),
          ],
        ],
      ),
    );
  }
}

class PaymentTypeChip extends StatelessWidget {
  const PaymentTypeChip({super.key, required this.type});

  final PaymentType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (type) {
      PaymentType.wage => theme.colorScheme.primary,
      PaymentType.advance => theme.colorScheme.tertiary,
      PaymentType.expenseRefund => theme.colorScheme.secondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
