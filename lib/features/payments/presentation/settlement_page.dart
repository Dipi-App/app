import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../core/utils/time_utils.dart';
import '../../../domain/enums.dart';
import '../../../shared/widgets/balance_chip.dart';
import '../../../shared/widgets/money_text.dart';
import '../../../shared/widgets/monthly_chart.dart';
import '../../../shared/widgets/section_card.dart';
import '../../employers/presentation/widgets/employer_avatar.dart';
import '../../employers/state/employer_providers.dart';
import '../state/payment_providers.dart';
import 'widgets/payment_form_sheet.dart';

class SettlementPage extends ConsumerWidget {
  const SettlementPage({super.key, required this.employerId});

  final int employerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employer = ref.watch(employerByIdProvider(employerId)).value;
    if (employer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تسویه حساب')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final summary = ref.watch(employerSettlementProvider(employerId));
    final theme = Theme.of(context);
    final color = AppColors.settlementColor(context, summary.state);

    return Scaffold(
      appBar: AppBar(title: const Text('تسویه حساب')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Column(
              children: [
                EmployerAvatar(
                  name: employer.name,
                  color: employer.color,
                  size: 52,
                ),
                const SizedBox(height: 12),
                Text(
                  employer.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  summary.state.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                MoneyText(
                  amountRial: summary.balanceRial.abs(),
                  animate: true,
                  withUnit: true,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                if (summary.state != SettlementState.settled)
                  Text(
                    summary.state == SettlementState.creditor
                        ? 'این مبلغ به شما بدهکار است.'
                        : 'این مبلغ به کارفرما بدهکارید.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'اجزای حساب',
            child: Column(
              children: [
                _Row(
                  label: 'جمع دستمزدها',
                  amountRial: summary.wageRial,
                  sign: '+',
                ),
                _Row(
                  label: 'هزینه‌های از جیب من',
                  amountRial: summary.outOfPocketRial,
                  sign: '+',
                ),
                _Row(
                  label: 'جمع پرداخت‌ها',
                  amountRial: summary.paymentsTotalRial,
                  sign: '−',
                  color: theme.colorScheme.error,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'مانده نهایی',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      BalanceChip(balanceRial: summary.balanceRial),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'نمودار ۱۲ ماه اخیر',
            child: _EmployerChart(employerId: employerId),
          ),
          if (summary.pendingCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.hourglass_empty_rounded,
                    size: 18,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${toPersianDigits(summary.pendingCount)} روزکار با دستمزد '
                      'نامعلوم هست و در این محاسبه نیامده است.',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SectionCard(
            title: 'پرداخت‌ها به تفکیک نوع',
            child: Column(
              children: [
                for (final type in PaymentType.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            type.label,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        MoneyText(
                          amountRial: summary.amountOf(type),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (summary.paymentCount == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'پرداختی ثبت نشده است.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'فعالیت',
            child: Column(
              children: [
                _StatRow(
                  label: 'روزهای کاری',
                  value: toPersianDigits(summary.dayCount),
                ),
                _StatRow(
                  label: 'تعداد روزکار',
                  value: toPersianDigits(summary.entryCount),
                ),
                _StatRow(
                  label: 'مجموع ساعت',
                  value: formatHours(summary.hours),
                ),
                _StatRow(
                  label: 'تعداد پرداخت',
                  value: toPersianDigits(summary.paymentCount),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                showPaymentFormSheet(context, initialEmployerId: employerId),
            icon: const Icon(Icons.add_rounded),
            label: const Text('ثبت پرداخت برای این کارفرما'),
          ),
        ],
      ),
    );
  }
}

class _EmployerChart extends ConsumerWidget {
  const _EmployerChart({required this.employerId});

  final int employerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(employerMonthlySeriesProvider(employerId));
    final hasData = series.any((point) => !point.isEmpty);
    if (!hasData) {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'در یک سال گذشته فعالیتی ثبت نشده.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return MonthlyChart(points: series, height: 210);
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.amountRial,
    required this.sign,
    this.color,
  });

  final String label;
  final int amountRial;
  final String sign;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Text(
            sign,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          MoneyText(
            amountRial: amountRial,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
