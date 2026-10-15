import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/enums.dart';
import '../../../shared/utils/motion.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/balance_chip.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/money_text.dart';
import '../../employers/state/employer_providers.dart';
import '../state/payment_providers.dart';
import 'widgets/payment_form_sheet.dart';
import 'widgets/payment_tile.dart';

class PaymentsPage extends ConsumerWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPayments = ref.watch(allPaymentsProvider);
    final payments = ref.watch(filteredPaymentsProvider);
    final employers = ref.watch(employersByIdProvider);
    final activeEmployers = ref.watch(activeEmployersProvider);
    final filter = ref.watch(paymentsFilterProvider);
    final controller = ref.read(paymentsFilterProvider.notifier);
    final overallBalance = ref.watch(overallBalanceProvider);
    final reduced = reduceMotion(context);
    final theme = Theme.of(context);

    final Widget body;
    if (asyncPayments.value == null) {
      body = asyncPayments.hasError
          ? EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'خواندن پرداخت‌ها ناموفق بود',
              message: '${asyncPayments.error}',
              action: FilledButton.tonal(
                onPressed: () => ref.invalidate(allPaymentsProvider),
                child: const Text('تلاش دوباره'),
              ),
            )
          : const Center(child: CircularProgressIndicator());
    } else if (asyncPayments.value!.isEmpty) {
      body = EmptyState(
        title: 'هنوز پرداختی ثبت نشده',
        message: 'دستمزدها، علی‌الحساب‌ها و بازپرداخت هزینه‌ها را اینجا ثبت کنید '
            'تا مانده حساب هر کارفرما دقیق بماند.',
        action: FilledButton.icon(
          onPressed: () => showPaymentFormSheet(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('ثبت پرداخت'),
        ),
      );
    } else {
      body = Column(
        children: [
          _SummaryCard(
            totalRial: ref.watch(filteredPaymentsTotalProvider),
            count: payments.length,
            overallBalance: overallBalance,
          ),
          _FilterBar(
            employers: activeEmployers,
            filter: filter,
            onEmployer: controller.setEmployer,
            onType: controller.setType,
            onClear: controller.clear,
          ),
          Expanded(
            child: payments.isEmpty
                ? EmptyState(
                    compact: true,
                    icon: Icons.filter_alt_off_outlined,
                    title: 'با این فیلترها پرداختی نیست',
                    message: 'فیلترها را پاک کنید تا همه پرداخت‌ها را ببینید.',
                    action: FilledButton.tonal(
                      onPressed: controller.clear,
                      child: const Text('پاک کردن فیلترها'),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                    itemCount: payments.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: theme.colorScheme.outlineVariant),
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      final tile = Dismissible(
                        key: ValueKey('payment-${payment.id}'),
                        direction: DismissDirection.horizontal,
                        confirmDismiss: (_) => confirmDialog(
                          context,
                          title: 'حذف پرداخت؟',
                          message: 'این پرداخت حذف می‌شود. تا چند لحظه می‌توانید '
                              'بازگردانید.',
                          confirmLabel: 'حذف',
                          destructive: true,
                        ),
                        onDismissed: (_) => _delete(context, ref, payment),
                        child: PaymentTile(
                          payment: payment,
                          employer: employers[payment.employerId],
                          onTap: () => showPaymentFormSheet(
                            context,
                            payment: payment,
                          ),
                        ),
                      );
                      if (reduced) return tile;
                      return tile
                          .animate()
                          .fadeIn(
                            delay: Duration(
                              milliseconds: 25 * index.clamp(0, 12),
                            ),
                            duration: 240.ms,
                          )
                          .slideY(begin: 0.05, end: 0, duration: 240.ms);
                    },
                  ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت‌ها')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showPaymentFormSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('پرداخت'),
      ),
      body: body,
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Payment payment,
  ) async {
    await ref.read(paymentDaoProvider).delete(payment.id);
    if (!context.mounted) return;
    showUndoSnackBar(
      context,
      message: 'پرداخت حذف شد.',
      onUndo: () => ref.read(paymentDaoProvider).restore(payment),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalRial,
    required this.count,
    required this.overallBalance,
  });

  final int totalRial;
  final int count;
  final int overallBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'جمع پرداخت‌ها',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                MoneyText(
                  amountRial: totalRial,
                  animate: true,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${toPersianDigits(count)} پرداخت',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'مانده کل',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              BalanceChip(balanceRial: overallBalance),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.employers,
    required this.filter,
    required this.onEmployer,
    required this.onType,
    required this.onClear,
  });

  final List<Employer> employers;
  final PaymentsFilter filter;
  final ValueChanged<int?> onEmployer;
  final ValueChanged<PaymentType?> onType;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              FilterChip(
                label: const Text('همه کارفرماها'),
                selected: filter.employerId == null,
                onSelected: (_) => onEmployer(null),
              ),
              for (final employer in employers) ...[
                const SizedBox(width: 8),
                FilterChip(
                  avatar: CircleAvatar(
                    backgroundColor: Color(employer.color),
                    radius: 6,
                  ),
                  label: Text(employer.name),
                  selected: filter.employerId == employer.id,
                  onSelected: (selected) =>
                      onEmployer(selected ? employer.id : null),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              FilterChip(
                label: const Text('همه انواع'),
                selected: filter.type == null,
                onSelected: (_) => onType(null),
              ),
              for (final type in PaymentType.values) ...[
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(type.label),
                  selected: filter.type == type,
                  onSelected: (selected) => onType(selected ? type : null),
                ),
              ],
              if (filter.isActive) ...[
                const SizedBox(width: 8),
                ActionChip(
                  avatar: Icon(
                    Icons.clear_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  label: const Text('پاک کردن'),
                  onPressed: onClear,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        Divider(height: 1, color: theme.colorScheme.outlineVariant),
      ],
    );
  }
}
