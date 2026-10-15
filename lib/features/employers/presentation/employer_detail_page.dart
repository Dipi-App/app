import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../core/widgets/directional_icons.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../core/utils/time_utils.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/enums.dart';
import '../../../domain/settlement.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/count_up_text.dart';
import '../../../shared/widgets/money_text.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/work_entry_tile.dart';
import '../../calendar/presentation/widgets/work_entry_form_sheet.dart';
import '../../payments/presentation/settlement_page.dart';
import '../../payments/presentation/widgets/payment_form_sheet.dart';
import '../../payments/presentation/widgets/payment_tile.dart';
import '../../payments/state/payment_providers.dart';
import '../state/employer_providers.dart';
import 'widgets/employer_avatar.dart';
import 'widgets/employer_form_sheet.dart';

class EmployerDetailPage extends ConsumerWidget {
  const EmployerDetailPage({super.key, required this.employerId});

  final int employerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEmployer = ref.watch(employerByIdProvider(employerId));
    final employer = asyncEmployer.value;

    if (asyncEmployer.hasValue && employer == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('این کارفرما پیدا نشد.')),
      );
    }
    if (employer == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final entries =
        ref.watch(employerEntriesProvider(employerId)).value ??
        const <WorkEntry>[];
    final payments =
        ref.watch(employerPaymentsProvider(employerId)).value ??
        const <Payment>[];
    final summary = ref.watch(employerSettlementProvider(employerId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(employer.name),
        actions: [
          IconButton(
            onPressed: () => showEmployerFormSheet(context, employer: employer),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'ویرایش',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenu(context, ref, employer, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: employer.isArchived ? 'unarchive' : 'archive',
                child: Text(
                  employer.isArchived ? 'بازگرداندن از بایگانی' : 'بایگانی کردن',
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'حذف کارفرما',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            showWorkEntryFormSheet(context, initialEmployerId: employer.id),
        icon: const Icon(Icons.add_rounded),
        label: const Text('روزکار'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _Header(employer: employer),
          const SizedBox(height: 12),
          _BalanceCard(summary: summary, employerId: employer.id),
          const SizedBox(height: 12),
          SectionCard(
            title: 'جمع کارفرما',
            child: Column(
              children: [
                Row(
                  children: [
                    _Stat(label: 'روز کاری', count: summary.dayCount),
                    _Stat(label: 'ساعت', value: formatHours(summary.hours)),
                    _Stat(label: 'روزکار', count: summary.entryCount),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Stat(
                      label: 'جمع دستمزد',
                      valueWidget: MoneyText(
                        amountRial: summary.wageRial,
                        animate: true,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E7D6F),
                        ),
                      ),
                    ),
                    _Stat(
                      label: 'از جیب خودم',
                      valueWidget: MoneyText(
                        amountRial: summary.outOfPocketRial,
                        animate: true,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _Stat(
                      label: 'پرداخت‌ها',
                      valueWidget: MoneyText(
                        amountRial: summary.paymentsTotalRial,
                        animate: true,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
            title: 'روزکارها',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (summary.pendingCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${toPersianDigits(summary.pendingCount)} در انتظار',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  toPersianDigits(summary.entryCount),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            child: entries.isEmpty
                ? _EmptyHint(
                    text: 'برای این کارفرما هنوز روزکاری ثبت نشده.',
                  )
                : Column(
                    children: [
                      for (final entry in entries)
                        Dismissible(
                          key: ValueKey('detail-entry-${entry.id}'),
                          direction: DismissDirection.horizontal,
                          confirmDismiss: (_) => confirmDialog(
                            context,
                            title: 'حذف روزکار؟',
                            message: 'این روزکار حذف می‌شود.',
                            confirmLabel: 'حذف',
                            destructive: true,
                          ),
                          onDismissed: (_) => _deleteEntry(context, ref, entry),
                          child: WorkEntryTile(
                            entry: entry,
                            employer: employer,
                            onTap: () => showWorkEntryFormSheet(
                              context,
                              entry: entry,
                            ),
                            trailing: Text(
                              formatJalaliShortIso(entry.date),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
            title: 'پرداخت‌ها',
            trailing: TextButton.icon(
              onPressed: () => showPaymentFormSheet(
                context,
                initialEmployerId: employer.id,
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('پرداخت'),
            ),
            child: payments.isEmpty
                ? _EmptyHint(text: 'برای این کارفرما پرداختی ثبت نشده.')
                : Column(
                    children: [
                      for (final payment in payments)
                        Dismissible(
                          key: ValueKey('detail-payment-${payment.id}'),
                          direction: DismissDirection.horizontal,
                          confirmDismiss: (_) => confirmDialog(
                            context,
                            title: 'حذف پرداخت؟',
                            message: 'این پرداخت حذف می‌شود.',
                            confirmLabel: 'حذف',
                            destructive: true,
                          ),
                          onDismissed: (_) =>
                              _deletePayment(context, ref, payment),
                          child: PaymentTile(
                            payment: payment,
                            employer: employer,
                            onTap: () =>
                                showPaymentFormSheet(context, payment: payment),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(
    BuildContext context,
    WidgetRef ref,
    WorkEntry entry,
  ) async {
    await ref.read(workEntryDaoProvider).delete(entry.id);
    if (!context.mounted) return;
    showUndoSnackBar(
      context,
      message: 'روزکار حذف شد.',
      onUndo: () => ref.read(workEntryDaoProvider).restore(entry),
    );
  }

  Future<void> _deletePayment(
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

  Future<void> _handleMenu(
    BuildContext context,
    WidgetRef ref,
    Employer employer,
    String action,
  ) async {
    final dao = ref.read(employerDaoProvider);
    switch (action) {
      case 'archive':
        await dao.setArchived(employer.id, true);
        if (context.mounted) showInfoSnackBar(context, 'کارفرما بایگانی شد.');
      case 'unarchive':
        await dao.setArchived(employer.id, false);
        if (context.mounted) showInfoSnackBar(context, 'کارفرما برگردانده شد.');
      case 'delete':
        final confirmed = await confirmDialog(
          context,
          title: 'حذف «${employer.name}»؟',
          message: 'همه روزکارها و پرداخت‌های این کارفرما هم حذف می‌شوند و '
              'این کار برگشت‌پذیر نیست.',
          confirmLabel: 'حذف',
          destructive: true,
        );
        if (!confirmed) return;
        await dao.delete(employer.id);
        if (context.mounted) {
          Navigator.of(context).pop();
          showInfoSnackBar(context, 'کارفرما حذف شد.');
        }
    }
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary, required this.employerId});

  final SettlementSummary summary;
  final int employerId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors.settlementColor(context, summary.state);

    return Card(
      color: color.withValues(alpha: 0.10),
      child: Pressable(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SettlementPage(employerId: employerId),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مانده حساب',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          summary.state.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: MoneyText(
                            amountRial: summary.balanceRial.abs(),
                            animate: true,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'تسویه حساب',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                    ),
                  ),
                  Icon(DirectionalIcons.forward, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.employer});

  final Employer employer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = (employer.phone ?? '').trim();
    final note = (employer.note ?? '').trim();
    final wageType = WageType.fromName(employer.defaultWageType);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Hero(
                  tag: 'employer-avatar-${employer.id}',
                  child: EmployerAvatar(
                    name: employer.name,
                    color: employer.color,
                    size: 58,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employer.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'دستمزد پیش‌فرض: ${wageType.label}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (employer.defaultDailyWage != null)
                            MoneyText(
                              amountRial: employer.defaultDailyWage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(toPersianDigits(phone)),
                ],
              ),
            ],
            if (note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      toPersianDigits(note),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, this.value, this.count, this.valueWidget});

  final String label;
  final String? value;
  final int? count;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          valueWidget ??
              (count != null
                  ? CountUpText(
                      value: count!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : Text(
                      value ?? '—',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    )),
          const SizedBox(height: 2),
          Text(
            label,
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
