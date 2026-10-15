import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../core/utils/time_utils.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/settlement.dart';
import '../../../domain/stats.dart';
import '../../../shared/utils/motion.dart';
import '../../../shared/widgets/balance_chip.dart';
import '../../../shared/widgets/count_up_text.dart';
import '../../../shared/widgets/employer_dot.dart';
import '../../../shared/widgets/jalali_date_picker.dart';
import '../../../shared/widgets/money_text.dart';
import '../../../shared/widgets/monthly_chart.dart';
import '../../../shared/widgets/section_card.dart';
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
    final reduced = reduceMotion(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('آمار'),
        actions: [
          IconButton(
            onPressed: () => _pickRange(context, ref, filter),
            icon: const Icon(Icons.date_range_outlined),
            tooltip: 'بازه دلخواه',
          ),
        ],
      ),
      body: !entriesReady
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _FilterChips(
                  filter: filter,
                  employers: activeEmployers,
                  onEmployer: controller.setEmployer,
                  onPreset: controller.setPreset,
                ),
                const SizedBox(height: 12),
                _TotalsCard(totals: totals, filter: filter, reduced: reduced),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'نمودار ماهانه',
                  child: series.isEmpty
                      ? const _NoData()
                      : MonthlyChart(points: series),
                ),
                if (filter.employerId == null) ...[
                  const SizedBox(height: 12),
                  SectionCard(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
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
                                _EmployerRow(
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
    final from = await showJalaliDatePicker(
      context,
      initialDate: filter.from,
    );
    if (from == null || !context.mounted) return;
    final to = await showJalaliDatePicker(context, initialDate: filter.to);
    if (to == null || !context.mounted) return;
    ref.read(statsFilterProvider.notifier).setRange(from, to);
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filter,
    required this.employers,
    required this.onEmployer,
    required this.onPreset,
  });

  final StatsFilter filter;
  final List<Employer> employers;
  final ValueChanged<int?> onEmployer;
  final ValueChanged<StatsRangePreset> onPreset;

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

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.totals,
    required this.filter,
    required this.reduced,
  });

  final SettlementSummary totals;
  final StatsFilter filter;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tiles = <Widget>[
      _StatTile(
        label: 'روز کاری',
        count: totals.dayCount,
        icon: Icons.event_available_outlined,
        reduced: reduced,
      ),
      _StatTile(
        label: 'ساعت',
        value: formatHours(totals.hours),
        icon: Icons.schedule_outlined,
      ),
      _StatTile(
        label: 'دستمزد',
        amountRial: totals.wageRial,
        icon: Icons.payments_outlined,
        color: const Color(AppColors.creditor),
        reduced: reduced,
      ),
      _StatTile(
        label: 'از جیب خودم',
        amountRial: totals.outOfPocketRial,
        icon: Icons.account_balance_wallet_outlined,
        reduced: reduced,
      ),
      _StatTile(
        label: 'دریافتی',
        amountRial: totals.paymentsTotalRial,
        icon: Icons.savings_outlined,
        color: theme.colorScheme.error,
        reduced: reduced,
      ),
      if (totals.pendingCount > 0)
        _StatTile(
          label: 'در انتظار',
          count: totals.pendingCount,
          icon: Icons.hourglass_empty_rounded,
          color: theme.colorScheme.tertiary,
          reduced: reduced,
        ),
    ];

    return SectionCard(
      title: 'جمع بازه',
      trailing: BalanceChip(balanceRial: totals.balanceRial, compact: true),
      child: Column(
        children: [
          for (var row = 0; row < (tiles.length / 3).ceil(); row++)
            Padding(
              padding: EdgeInsets.only(top: row == 0 ? 0 : 16),
              child: Row(
                children: [
                  for (var col = 0; col < 3; col++)
                    Expanded(
                      child: row * 3 + col < tiles.length
                          ? tiles[row * 3 + col]
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    this.value,
    this.count,
    this.amountRial,
    required this.icon,
    this.color,
    this.reduced = true,
  });

  final String label;
  final String? value;
  final int? count;
  final int? amountRial;
  final IconData icon;
  final Color? color;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurface;

    return Column(
      children: [
        Icon(icon, size: 18, color: effectiveColor.withValues(alpha: 0.75)),
        const SizedBox(height: 6),
        if (amountRial != null)
          MoneyText(
            amountRial: amountRial!,
            animate: !reduced,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: effectiveColor,
            ),
          )
        else if (count != null)
          CountUpText(
            value: count!,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: effectiveColor,
            ),
          )
        else
          Text(
            value ?? '—',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: effectiveColor,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EmployerRow extends StatelessWidget {
  const _EmployerRow({required this.ledger, required this.employer});

  final EmployerLedger ledger;
  final Employer? employer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = employer?.name ?? 'کارفرمای حذف‌شده';
    final color = Color(employer?.color ?? 0xFF7A7A7A);

    return Pressable(
      onTap: employer == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettlementPage(employerId: employer!.id),
              ),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Row(
          children: [
            EmployerAvatar(
              name: name,
              color: employer?.color ?? 0xFF7A7A7A,
              size: 38,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          EmployerDot(color: color, size: 8),
                          const SizedBox(width: 6),
                          Text(
                            '${toPersianDigits(ledger.totals.dayCount)} روز'
                            ' · ${formatHours(ledger.totals.hours)} ساعت',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      MoneyText(
                        amountRial: ledger.totals.earnedRial,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      BalanceChip(
                        balanceRial: ledger.totals.balanceRial,
                        compact: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
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
