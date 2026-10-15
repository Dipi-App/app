import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/help/help_page.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/enums.dart';
import '../../../shared/utils/motion.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/settings_button.dart';
import '../../settings/state/settings_providers.dart';
import '../state/employer_providers.dart';
import 'employer_detail_page.dart';
import 'widgets/employer_avatar.dart';
import 'widgets/employer_form_sheet.dart';

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
          final tile = _EmployerTile(employer: list[index]);
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
      appBar: AppBar(
        title: Text(_showArchived ? 'کارفرماهای بایگانی' : 'کارفرماها'),
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
      floatingActionButton: FloatingActionButton.extended(
        // The tabs live together in an IndexedStack; a default hero tag would
        // clash with the payments FAB during route transitions.
        heroTag: null,
        onPressed: () => showEmployerFormSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('کارفرما'),
      ),
      body: body,
    );
  }
}

class _EmployerTile extends ConsumerWidget {
  const _EmployerTile({required this.employer});

  final Employer employer;

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
          child: Row(
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
              Icon(Icons.chevron_left_rounded, color: theme.colorScheme.outline),
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
