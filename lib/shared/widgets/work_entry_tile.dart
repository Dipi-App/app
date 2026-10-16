import 'package:flutter/material.dart';

import '../../core/utils/time_utils.dart';
import '../../data/db/app_database.dart';
import '../../domain/allocation.dart';
import '../../domain/enums.dart';
import 'employer_dot.dart';
import 'money_text.dart';

class WorkEntryTile extends StatelessWidget {
  const WorkEntryTile({
    super.key,
    required this.entry,
    required this.employer,
    this.allocation,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  final WorkEntry entry;
  final Employer? employer;

  /// Optional payment allocation so a pending day covered by the employer's
  /// payments is shown with its amount instead of the "in wait" badge.
  final AllocationResult? allocation;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(employer?.color ?? 0xFF7A7A7A);
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final allocationAmount = entry.wageAmount == null
        ? allocation?.amountFor(entry.id)
        : null;
    final effectiveWage = entry.wageAmount ?? allocationAmount;
    final title = [
      if ((entry.place ?? '').trim().isNotEmpty) entry.place!.trim(),
      if ((entry.job ?? '').trim().isNotEmpty) entry.job!.trim(),
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: EmployerDot(color: color, size: 12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employer?.name ?? 'کارفرمای حذف‌شده',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (title.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (entry.startTime != null && entry.endTime != null)
                        _Meta(
                          icon: Icons.schedule_rounded,
                          child: Text(
                            '${formatClockText(entry.startTime)} تا '
                            '${formatClockText(entry.endTime)} '
                            '(${formatDuration(shiftDuration(entry.startTime, entry.endTime))})',
                            style: metaStyle,
                          ),
                        )
                      else
                        _Meta(
                          icon: Icons.timelapse_rounded,
                          child: Text('بدون ساعت', style: metaStyle),
                        ),
                      if (effectiveWage == null)
                        _Badge(
                          text: 'دستمزد در انتظار',
                          color: theme.colorScheme.tertiary,
                        )
                      else
                        _Meta(
                          icon: Icons.payments_outlined,
                          child: MoneyText(
                            amountRial: effectiveWage,
                            style: metaStyle,
                          ),
                        ),
                      if (entry.outOfPocketAmount > 0)
                        _Meta(
                          icon: Icons.account_balance_wallet_outlined,
                          child: MoneyText(
                            amountRial: entry.outOfPocketAmount,
                            withUnit: false,
                            style: metaStyle,
                          ),
                        ),
                      if (WageType.fromName(entry.wageType) == WageType.variable)
                        _Badge(
                          text: 'متغیر',
                          color: theme.colorScheme.secondary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.child});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        child,
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
