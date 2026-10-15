import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/help/help_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../core/widgets/directional_icons.dart';
import '../../../core/widgets/dipi_header.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/enums.dart';
import '../../../domain/settlement.dart';
import '../../../domain/stats.dart';
import '../../../shared/widgets/balance_chip.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/jalali_date_picker.dart';
import '../../../shared/widgets/money_text.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/settings_button.dart';
import '../../../shared/widgets/simple_bar_chart.dart';
import '../../app_update/presentation/widgets/update_header_button.dart';
import '../../calendar/presentation/widgets/work_entry_form_sheet.dart';
import '../../employers/presentation/widgets/employer_avatar.dart';
import '../../employers/state/employer_providers.dart';
import '../../payments/presentation/settlement_page.dart';
import '../state/stats_providers.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(statsFilterProvider);
    final controller = ref.read(statsFilterProvider.notifier);
    final totals = ref.watch(statsTotalsProvider);
    final series = ref.watch(statsMonthlySeriesProvider);
    final ledgers = ref.watch(statsEmployerLedgersProvider);
    final employers = ref.watch(employersByIdProvider);
    final activeEmployers = ref.watch(activeEmployersProvider);
    final entriesReady = ref.watch(statsEntriesProvider).hasValue;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: DipiHeader(
        title: 'آمار',
        updateAction: const UpdateHeaderButton(),
        actions: [
          IconButton(
            onPressed: () => _pickRange(context, ref, filter),
            icon: const Icon(Icons.date_range_outlined),
            tooltip: 'بازه دلخواه',
          ),
          const ContextHelpButton(topicId: 'see-balance'),
          const SettingsButton(),
        ],
      ),
      body: !entriesReady
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                AppTokens.navClearance(context),
              ),
              children: [
                _FilterBar(
                  filter: filter,
                  employers: activeEmployers,
                  onEmployer: controller.setEmployer,
                  onPreset: controller.setPreset,
                  onCustomRange: () => _pickRange(context, ref, filter),
                ),
                const SizedBox(height: 12),
                if (totals.isEmpty)
                  EmptyState(
                    title: 'در این بازه داده‌ای نیست',
                    message: 'بازه را عوض کن یا اولین روزکار این بازه را ثبت کن.',
                    action: FilledButton.icon(
                      onPressed: () => showWorkEntryFormSheet(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('ثبت روزکار'),
                    ),
                  )
                else ...[
                  SectionCard(
                    title: 'جمع بازه',
                    child: Column(
                      children: [
                        _BalanceHero(totals: totals),
                        const SizedBox(height: 14),
                        _StatCard(
                          icon: Icons.event_available_outlined,
                          label: 'روزهای کارکرد',
                          value: '${toPersianDigits(totals.dayCount)} روز',
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(height: 10),
                        _StatCard(
                          icon: Icons.payments_outlined,
                          label: 'دستمزد',
                          amountRial: totals.wageRial,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(height: 10),
                        _StatCard(
                          icon: Icons.savings_outlined,
                          label: 'دریافتی',
                          amountRial: totals.paymentsTotalRial,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 10),
                        _StatCard(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'هزینه از جیب',
                          amountRial: totals.outOfPocketRial,
                          color: theme.colorScheme.tertiary,
                        ),
                        if (totals.pendingCount > 0) ...[
                          const SizedBox(height: 10),
                          _StatCard(
                            icon: Icons.hourglass_empty_rounded,
                            label: 'دستمزد در انتظار',
                            value: '${toPersianDigits(totals.pendingCount)} مورد',
                            color: theme.colorScheme.tertiary,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'نمودار ماهانه',
                    child: series.isEmpty
                        ? const _NoData()
                        : SimpleBarChart(points: series),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    title: 'به تفکیک کارفرما',
                    trailing: Text(
                      toPersianDigits(ledgers.length),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    child: ledgers.isEmpty
                        ? const _NoData()
                        : Column(
                            children: [
                              for (final ledger in ledgers)
                                _EmployerCard(
                                  ledger: ledger,
                                  employer: employers[ledger.employerId],
                                ),
                            ],
                          ),
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _pickRange(
    BuildContext context,
    WidgetRef ref,
    StatsFilter filter,
  ) async {
    final from = await showJalaliDatePicker(context, initialDate: filter.from);
    if (from == null || !context.mounted) return;
    final to = await showJalaliDatePicker(context, initialDate: filter.to);
    if (to == null || !context.mounted) return;
    ref.read(statsFilterProvider.notifier).setRange(from, to);
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.employers,
    required this.onEmployer,
    required this.onPreset,
    required this.onCustomRange,
  });

  final StatsFilter filter;
  final List<Employer> employers;
  final ValueChanged<int?> onEmployer;
  final ValueChanged<StatsRangePreset> onPreset;
  final VoidCallback onCustomRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final preset in StatsRangePreset.values) ...[
                if (preset != StatsRangePreset.values.first)
                  const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(preset.label),
                  selected: filter.preset == preset,
                  onSelected: (_) => onPreset(preset),
                ),
              ],
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.date_range_outlined, size: 18),
                label: const Text('بازه دلخواه'),
                onPressed: onCustomRange,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('همه کارفرماها'),
                selected: filter.employerId == null,
                onSelected: (_) => onEmployer(null),
              ),
              for (final employer in employers) ...[
                const SizedBox(width: 8),
                ChoiceChip(
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
        const SizedBox(height: 8),
        Text(
          '${formatJalaliMonthYear(filter.from)} تا ${formatJalaliMonthYear(filter.to)}'
          ' · ${toPersianDigits(filter.monthCount)} ماه',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.totals});

  final SettlementSummary totals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = totals.state;
    final color = AppColors.settlementColor(context, state);
    final icon = switch (state) {
      SettlementState.creditor => Icons.trending_up_rounded,
      SettlementState.debtor => Icons.trending_down_rounded,
      SettlementState.settled => Icons.check_circle_outline_rounded,
    };
    final hint = switch (state) {
      SettlementState.creditor => 'کارفرماها به تو بدهکارند',
      SettlementState.debtor => 'تو به کارفرماها بدهکاری',
      SettlementState.settled => 'حساب‌ها تسویه است',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withValues(alpha: 0.18),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                MoneyText(
                  amountRial: totals.balanceRial.abs(),
                  animate: true,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.color,
    this.value,
    this.amountRial,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String? value;
  final int? amountRial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(icon, size: 26, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                if (amountRial != null)
                  MoneyText(
                    amountRial: amountRial!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  )
                else
                  Text(
                    value ?? '—',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployerCard extends StatelessWidget {
  const _EmployerCard({required this.ledger, required this.employer});

  final EmployerLedger ledger;
  final Employer? employer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = employer?.name ?? 'کارفرمای حذف‌شده';
    final color = Color(employer?.color ?? 0xFF7A7A7A);
    final totals = ledger.totals;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        onTap: employer == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettlementPage(employerId: employer!.id),
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  EmployerAvatar(name: name, color: employer?.color ?? 0xFF7A7A7A, size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(DirectionalIcons.forward, color: theme.colorScheme.outline),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _Chip(
                    icon: Icons.event_available_outlined,
                    text: '${toPersianDigits(totals.dayCount)} روز',
                  ),
                  _Chip(
                    icon: Icons.payments_outlined,
                    textWidget: MoneyText(
                      amountRial: totals.earnedRial,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  _Chip(
                    icon: Icons.savings_outlined,
                    textWidget: MoneyText(
                      amountRial: totals.paymentsTotalRial,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: BalanceChip(balanceRial: totals.balanceRial),
              ),
              const SizedBox(height: 2),
              Container(height: 3, width: 40, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, this.text, this.textWidget});

  final IconData icon;
  final String? text;
  final Widget? textWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        textWidget ??
            Text(
              text ?? '—',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      ],
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'در این بازه داده‌ای نیست.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
