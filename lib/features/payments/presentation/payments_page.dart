import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/help/help_page.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../core/widgets/dipi_header.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/enums.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/balance_chip.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/fade_scroll.dart';
import '../../../shared/widgets/jalali_date_picker.dart';
import '../../../shared/widgets/money_text.dart';
import '../../../shared/widgets/settings_button.dart';
import '../../app_update/presentation/widgets/update_header_button.dart';
import '../../employers/state/employer_providers.dart';
import '../state/payment_providers.dart';
import 'widgets/payment_form_sheet.dart';
import 'widgets/payment_tile.dart';

class PaymentsPage extends ConsumerWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPayments = ref.watch(allPaymentsProvider);
    final groups = ref.watch(filteredPaymentGroupsProvider);
    final employers = ref.watch(employersByIdProvider);
    final activeEmployers = ref.watch(activeEmployersProvider);
    final filter = ref.watch(paymentsFilterProvider);
    final controller = ref.read(paymentsFilterProvider.notifier);
    final total = ref.watch(filteredPaymentsTotalProvider);
    final balance = ref.watch(overallBalanceProvider);

    final Widget body;
    if (asyncPayments.hasError) {
      body = EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'خواندن پرداخت‌ها ناموفق بود',
        message: '${asyncPayments.error}',
        action: FilledButton.tonal(
          onPressed: () => ref.invalidate(allPaymentsProvider),
          child: const Text('تلاش دوباره'),
        ),
      );
    } else if (asyncPayments.value == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: Column(
                children: [
                  _SummaryBar(
                    totalRial: total,
                    count: groups.fold(
                      0,
                      (sum, group) => sum + group.payments.length,
                    ),
                    balanceRial: balance,
                  ),
                  const SizedBox(height: 10),
                  _FilterBar(
                    employers: activeEmployers,
                    filter: filter,
                    onEmployer: controller.setEmployer,
                    onType: controller.setType,
                    onPickRange: () => _pickRange(context, ref, filter),
                    onClearRange: controller.clearRange,
                    onClear: controller.clear,
                  ),
                ],
              ),
            ),
          ),
          if (groups.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: filter.isActive ? 'با این فیلترها پرداختی نیست' : 'هنوز پرداختی ثبت نشده',
                message: filter.isActive
                    ? 'فیلترها را پاک کن تا همه پرداخت‌ها را ببینی.'
                    : 'دستمزدها، علی‌الحساب‌ها و بازپرداخت هزینه‌ها را اینجا ثبت کن.',
                action: FilledButton.icon(
                  onPressed: () => showPaymentFormSheet(context),
                  icon: filter.isActive
                      ? const Icon(Icons.clear_rounded)
                      : const Icon(Icons.add_rounded),
                  label: Text(filter.isActive ? 'پاک کردن فیلترها' : 'ثبت پرداخت'),
                ),
              ),
            )
          else ...[
            for (final group in groups) ...[
              SliverPersistentHeader(
                pinned: true,
                delegate: _MonthHeaderDelegate(
                  month: group.month,
                  totalRial: group.totalRial,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                sliver: SliverList.builder(
                  itemCount: group.payments.length,
                  itemBuilder: (context, index) {
                    final payment = group.payments[index];
                    return Dismissible(
                      key: ValueKey('payment-${payment.id}'),
                      direction: DismissDirection.horizontal,
                      confirmDismiss: (_) => confirmDialog(
                        context,
                        title: 'حذف پرداخت؟',
                        message:
                            'این پرداخت حذف می‌شود. تا چند لحظه می‌توانی برگردانی.',
                        confirmLabel: 'حذف',
                        destructive: true,
                      ),
                      onDismissed: (_) => _delete(context, ref, payment),
                      child: PaymentTile(
                        payment: payment,
                        employer: employers[payment.employerId],
                        onTap: () =>
                            showPaymentFormSheet(context, payment: payment),
                      ),
                    );
                  },
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: SizedBox(height: AppTokens.navClearance(context)),
            ),
          ],
        ],
      );
    }

    return Scaffold(
      appBar: const DipiHeader(
        title: 'پرداخت‌ها',
        updateAction: UpdateHeaderButton(),
        actions: [
          ContextHelpButton(topicId: 'add-payment'),
          SettingsButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showPaymentFormSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('پرداخت'),
      ),
      body: body,
    );
  }

  Future<void> _pickRange(
    BuildContext context,
    WidgetRef ref,
    PaymentsFilter filter,
  ) async {
    final now = DateTime.now();
    final from = await showJalaliDatePicker(
      context,
      initialDate: filter.from ?? DateTime(now.year, now.month, 1),
    );
    if (from == null || !context.mounted) return;
    final to = await showJalaliDatePicker(context, initialDate: filter.to ?? now);
    if (to == null || !context.mounted) return;
    ref.read(paymentsFilterProvider.notifier).setRange(from, to);
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

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.totalRial,
    required this.count,
    required this.balanceRial,
  });

  final int totalRial;
  final int count;
  final int balanceRial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'جمع دریافتی',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                MoneyText(
                  amountRial: totalRial,
                  animate: true,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
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
              BalanceChip(balanceRial: balanceRial),
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
    required this.onPickRange,
    required this.onClearRange,
    required this.onClear,
  });

  final List<Employer> employers;
  final PaymentsFilter filter;
  final ValueChanged<int?> onEmployer;
  final ValueChanged<PaymentType?> onType;
  final VoidCallback onPickRange;
  final VoidCallback onClearRange;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rangeLabel = filter.hasRange
        ? '${formatJalaliShort(filter.from ?? filter.to!)} تا '
              '${formatJalaliShort(filter.to ?? filter.from!)}'
        : 'بازه تاریخ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeScroll(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
                      radius: 7,
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
        ),
        const SizedBox(height: 6),
        FadeScroll(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.date_range_outlined, size: 18),
                  label: Text(rangeLabel),
                  onPressed: onPickRange,
                ),
                if (filter.hasRange) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('حذف بازه'),
                    onPressed: onClearRange,
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
        ),
      ],
    );
  }
}

class _MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  _MonthHeaderDelegate({required this.month, required this.totalRial});

  final DateTime month;
  final int totalRial;

  @override
  double get minExtent => 46;

  @override
  double get maxExtent => 46;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatJalaliMonthYear(month),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            'جمع ماه: ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          MoneyText(
            amountRial: totalRial,
            withUnit: false,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_MonthHeaderDelegate oldDelegate) =>
      oldDelegate.month != month || oldDelegate.totalRial != totalRial;
}
