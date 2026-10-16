import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/help/help_page.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/directional_icons.dart';
import '../../../core/widgets/dipi_header.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/employer_stats.dart';
import '../../../domain/enums.dart';
import '../../../shared/utils/motion.dart';
import '../../../shared/widgets/balance_chip.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/nav_aware_fab.dart';
import '../../../shared/widgets/settings_button.dart';
import '../../app_update/presentation/widgets/update_header_button.dart';
import '../../payments/state/payment_providers.dart';
import '../../settings/state/settings_providers.dart';
import '../state/employer_providers.dart';
import 'employer_detail_page.dart';
import 'widgets/employer_avatar.dart';
import 'widgets/employer_form_sheet.dart';
import 'widgets/employer_stats_grid.dart';

class EmployersPage extends ConsumerStatefulWidget {
  const EmployersPage({super.key});

  @override
  ConsumerState<EmployersPage> createState() => _EmployersPageState();
}

class _EmployersPageState extends ConsumerState<EmployersPage> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final asyncEmployers = ref.watch(employersProvider);
    final active = ref.watch(activeEmployersProvider);
    final archived = ref.watch(archivedEmployersProvider);
    final statsByEmployer = ref.watch(employerStatsMapProvider);
    final balances = ref.watch(employerBalancesProvider);
    final list = _showArchived ? archived : active;
    final reduced = reduceMotion(context);

    final Widget body;
    if (asyncEmployers.value == null) {
      body = asyncEmployers.hasError
          ? EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'خواندن کارفرماها ناموفق بود',
              message: '${asyncEmployers.error}',
              action: FilledButton.tonal(
                onPressed: () => ref.invalidate(employersProvider),
                child: const Text('تلاش دوباره'),
              ),
            )
          : const Center(child: CircularProgressIndicator());
    } else if (active.isEmpty && archived.isEmpty) {
      body = EmptyState(
        title: 'هنوز کارفرمایی ثبت نشده',
        message: 'کارفرما را اضافه کنید و یک رنگ برایش انتخاب کنید تا روزهای '
            'کاری‌اش روی تقویم با همان رنگ دیده شود.',
        action: FilledButton.icon(
          onPressed: () => showEmployerFormSheet(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('افزودن کارفرما'),
        ),
      );
    } else if (list.isEmpty) {
      body = EmptyState(
        compact: true,
        icon: Icons.inventory_2_outlined,
        title: _showArchived
            ? 'کارفرمای بایگانی‌شده‌ای نیست'
            : 'همه کارفرماها بایگانی شده‌اند',
        message: _showArchived
            ? 'کارفرماهایی که بایگانی می‌کنید اینجا می‌مانند و اطلاعاتشان پاک نمی‌شود.'
            : 'با دکمه بالا کارفرماهای بایگانی‌شده را ببینید و برگردانید.',
      );
    } else {
      body = ListView.separated(
        padding: EdgeInsets.fromLTRB(
          12,
          8,
          12,
          AppTokens.navClearance(context),
        ),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final employer = list[index];
          final tile = _EmployerTile(
            employer: employer,
            stats: statsByEmployer[employer.id] ?? const EmployerStats.empty(),
            balanceRial: balances[employer.id] ?? 0,
          );
          if (reduced) return tile;
          return tile
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 25 * index.clamp(0, 12)),
                duration: 260.ms,
              )
              .slideY(begin: 0.06, end: 0, duration: 260.ms);
        },
      );
    }

    return Scaffold(
      appBar: DipiHeader(
        title: _showArchived ? 'کارفرماهای بایگانی' : 'کارفرماها',
        updateAction: const UpdateHeaderButton(),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showArchived = !_showArchived),
            icon: Icon(
              _showArchived
                  ? Icons.people_alt_rounded
                  : Icons.inventory_2_outlined,
            ),
            tooltip: _showArchived ? 'کارفرماهای فعال' : 'کارفرماهای بایگانی‌شده',
          ),
          const ContextHelpButton(topicId: 'employers'),
          const SettingsButton(),
        ],
      ),
      floatingActionButton: NavAwareFab(
        child: FloatingActionButton.extended(
          // The tabs live together in an IndexedStack; a default hero tag would
          // clash with the payments FAB during route transitions.
          heroTag: null,
          onPressed: () => showEmployerFormSheet(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('کارفرما'),
        ),
      ),
      body: body,
    );
  }
}

class _EmployerTile extends ConsumerWidget {
  const _EmployerTile({
    required this.employer,
    required this.stats,
    required this.balanceRial,
  });

  final Employer employer;
  final EmployerStats stats;
  final int balanceRial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unit = ref.watch(
      settingsControllerProvider.select(
        (settings) => settings.value?.currencyUnit ?? CurrencyUnit.toman,
      ),
    );
    final phone = (employer.phone ?? '').trim();
    final wageType = WageType.fromName(employer.defaultWageType);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EmployerDetailPage(employerId: employer.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'employer-avatar-${employer.id}',
                    child: EmployerAvatar(
                      name: employer.name,
                      color: employer.color,
                      size: 46,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                employer.name,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (employer.isArchived) ...[
                              const SizedBox(width: 8),
                              _Tag(
                                text: 'بایگانی',
                                color: theme.colorScheme.outline,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (phone.isNotEmpty) toPersianDigits(phone),
                            wageType.label,
                            if (employer.defaultDailyWage != null)
                              formatMoney(employer.defaultDailyWage!, unit),
                          ].join(' — '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(DirectionalIcons.forward, color: theme.colorScheme.outline),
                ],
              ),
              const SizedBox(height: 14),
              EmployerStatsGrid(stats: stats, dense: true),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: BalanceChip(balanceRial: balanceRial, compact: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

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
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
