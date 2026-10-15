import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/help/coach_mark.dart';
import '../../../core/help/help_page.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../core/utils/time_utils.dart';
import '../../../core/widgets/directional_icons.dart';
import '../../../core/widgets/dipi_header.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/enums.dart';
import '../../../shared/utils/motion.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/money_text.dart';
import '../../../shared/widgets/settings_button.dart';
import '../../app_update/presentation/widgets/update_header_button.dart';
import '../../employers/presentation/widgets/employer_avatar.dart';
import '../../employers/state/employer_providers.dart';
import '../state/calendar_providers.dart';
import 'widgets/day_cell.dart';
import 'widgets/work_entry_form_sheet.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  static const int _basePage = 5000;

  late final DateTime _baseMonth;
  late final PageController _controller;
  late DateTime _selected;
  final _calendarKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _baseMonth = ref.read(visibleMonthProvider);
    _selected = dateOnly(DateTime.now());
    _controller = PageController(initialPage: _basePage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showCoachMarks(
        context,
        ref,
        id: 'calendar',
        steps: [
          CoachMarkStep(
            targetKey: _calendarKey,
            title: 'تقویم ماه',
            message: 'روی هر روز بزن تا کارهای آن روز را پایین صفحه ببینی.',
          ),
        ],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _pageForMonth(DateTime month) {
    final from = toJalali(_baseMonth);
    final to = toJalali(month);
    final diff = (to.year - from.year) * 12 + (to.month - from.month);
    return _basePage + diff;
  }

  DateTime _monthForPage(int page) {
    return toJalali(_baseMonth)
        .addMonths(page - _basePage)
        .withDay(1)
        .toDateTime();
  }

  void _goToMonth(DateTime month) {
    _controller.animateToPage(
      _pageForMonth(month),
      duration: reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _openDay(DateTime day) {
    setState(() => _selected = dateOnly(day));
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(visibleMonthProvider);
    final reduced = reduceMotion(context);

    return Scaffold(
      appBar: DipiHeader(
        title: formatJalaliMonthYear(month),
        updateAction: const UpdateHeaderButton(),
        leading: IconButton(
          onPressed: () => _goToMonth(previousJalaliMonth(month)),
          icon: const Icon(DirectionalIcons.back),
          tooltip: 'ماه قبل',
        ),
        actions: [
          IconButton(
            onPressed: () => _goToMonth(nextJalaliMonth(month)),
            icon: const Icon(DirectionalIcons.forward),
            tooltip: 'ماه بعد',
          ),
          IconButton(
            onPressed: () => _goToMonth(DateTime.now()),
            icon: const Icon(Icons.today_rounded),
            tooltip: 'امروز',
          ),
          const ContextHelpButton(topicId: 'calendar-overview'),
          const SettingsButton(),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // The calendar keeps a stable height; the day card below takes the
          // rest and scrolls, so a busy day never gets clipped.
          final calendarHeight = (constraints.maxHeight * 0.5)
              .clamp(280.0, 460.0)
              .toDouble();
          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: AppTokens.navClearance(context)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: calendarHeight,
                    child: _CalendarCard(
                      key: _calendarKey,
                      controller: _controller,
                      baseMonth: _baseMonth,
                      selected: _selected,
                      month: month,
                      onDayTap: _openDay,
                      onMonthChanged: (page) => ref
                          .read(visibleMonthProvider.notifier)
                          .goTo(_monthForPage(page)),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: reduced
                        ? Duration.zero
                        : const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _SelectedDayCard(
                      key: ValueKey('day-${toIsoDate(_selected)}'),
                      day: _selected,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    super.key,
    required this.controller,
    required this.baseMonth,
    required this.selected,
    required this.month,
    required this.onDayTap,
    required this.onMonthChanged,
  });

  static const int _basePage = 5000;

  final PageController controller;
  final DateTime baseMonth;
  final DateTime selected;
  final DateTime month;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<int> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        child: Column(
          children: [
            const _WeekdayHeader(),
            Expanded(
              child: PageView.builder(
                controller: controller,
                onPageChanged: onMonthChanged,
                itemBuilder: (context, page) {
                  final pageMonth = toJalali(baseMonth)
                      .addMonths(page - _basePage)
                      .withDay(1)
                      .toDateTime();
                  return _MonthGrid(
                    month: pageMonth,
                    selected: selected,
                    onDayTap: onDayTap,
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            _MonthSummaryBar(monthKey: jalaliMonthKey(month)),
            const SizedBox(height: 8),
            const _CalendarLegend(),
          ],
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          for (final label in jalaliWeekdayShort)
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.onDayTap,
  });

  final DateTime month;
  final DateTime selected;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cells = jalaliMonthGrid(month);
    final monthKey = jalaliMonthKey(month);
    final colorsByDay = ref.watch(monthDayColorsProvider(monthKey));
    final pendingDays = ref.watch(monthPendingDaysProvider(monthKey));
    final rows = cells.length ~/ 7;

    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Expanded(
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(child: _cell(cells[row * 7 + col], colorsByDay, pendingDays)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(
    DateTime? day,
    Map<String, List<int>> colorsByDay,
    Set<String> pendingDays,
  ) {
    if (day == null) return const SizedBox.shrink();
    final iso = toIsoDate(day);
    return DayCell(
      day: day,
      colors: colorsByDay[iso] ?? const [],
      hasPending: pendingDays.contains(iso),
      selected: isSameDay(day, selected),
      onTap: () => onDayTap(day),
    );
  }
}

class _MonthSummaryBar extends ConsumerWidget {
  const _MonthSummaryBar({required this.monthKey});

  final String monthKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(monthTotalsProvider(monthKey));
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryChip(
            icon: Icons.event_available_outlined,
            label: 'کارکرد',
            value: '${toPersianDigits(totals.dayCount)} روز',
            style: style,
          ),
          _SummaryChip(
            icon: Icons.schedule_outlined,
            label: 'ساعت کار',
            value: '${formatHours(totals.hours)} ساعت',
            style: style,
          ),
          _SummaryChip(
            icon: Icons.payments_outlined,
            label: 'دستمزد',
            valueWidget: MoneyText(
              amountRial: totals.wageRial,
              withUnit: true,
              style: style?.copyWith(fontWeight: FontWeight.w700),
            ),
            style: style,
          ),
          if (totals.pendingCount > 0)
            _SummaryChip(
              icon: Icons.hourglass_empty_rounded,
              label: 'در انتظار',
              value: '${toPersianDigits(totals.pendingCount)} روز',
              style: style?.copyWith(color: theme.colorScheme.tertiary),
            ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
    this.style,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: style?.color),
              const SizedBox(width: 4),
              Flexible(
                child: valueWidget ??
                    Text(
                      value ?? '—',
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Explains the small dots used on calendar days.
class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        _LegendItem(
          style: style,
          marker: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          label: 'رنگ کارفرما',
        ),
        _LegendItem(
          style: style,
          marker: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scheme.secondary, width: 2),
            ),
          ),
          label: 'امروز',
        ),
        _LegendItem(
          style: style,
          marker: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: scheme.tertiary,
              shape: BoxShape.circle,
            ),
          ),
          label: 'در انتظار',
        ),
        Text('چند نقطه = چند کارفرما', style: style),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.marker, required this.label, this.style});

  final Widget marker;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        marker,
        const SizedBox(width: 4),
        Text(label, style: style),
      ],
    );
  }
}

class _SelectedDayCard extends ConsumerWidget {
  const _SelectedDayCard({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iso = toIsoDate(day);
    final entries =
        ref.watch(dayEntriesProvider(iso)).value ?? const <WorkEntry>[];
    final employers = ref.watch(employersByIdProvider);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_note_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formatJalaliFullLong(day),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (entries.isEmpty)
              const _EmptyDay()
            else
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) const Divider(height: 20),
                _DayEntry(
                  entry: entries[i],
                  employer: employers[entries[i].employerId],
                ),
              ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _addWorkday(context, iso),
              icon: const Icon(Icons.add_rounded),
              label: const Text('افزودن روزکار'),
            ),
          ],
        ),
      ),
    );
  }

  void _addWorkday(BuildContext context, String iso) {
    showWorkEntryFormSheet(context, initialDate: iso);
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Icon(
            Icons.weekend_outlined,
            size: 44,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 10),
          Text(
            'این روز روزکاری ثبت نشده',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'با دکمه پایین اولین روزکار این روز را ثبت کن.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayEntry extends ConsumerWidget {
  const _DayEntry({required this.entry, required this.employer});

  final WorkEntry entry;
  final Employer? employer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = Color(employer?.color ?? 0xFF7A7A7A);
    final note = (entry.note ?? '').trim();
    final place = (entry.place ?? '').trim();
    final job = (entry.job ?? '').trim();
    final wageType = WageType.fromName(entry.wageType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            EmployerAvatar(
              name: employer?.name ?? '?',
              color: employer?.color ?? 0xFF7A7A7A,
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                employer?.name ?? 'کارفرمای حذف‌شده',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (place.isNotEmpty)
          _DetailRow(icon: Icons.place_outlined, label: 'محل کار', value: place),
        if (job.isNotEmpty)
          _DetailRow(icon: Icons.work_outline_rounded, label: 'نوع کار', value: job),
        _DetailRow(
          icon: Icons.schedule_rounded,
          label: 'ساعت کار',
          value: _timeText(entry),
        ),
        _DetailRow(
          icon: Icons.payments_outlined,
          label: 'دستمزد (${wageType.label})',
          child: entry.wageAmount == null
              ? Text(
                  'در انتظار',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : MoneyText(
                  amountRial: entry.wageAmount!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
        ),
        if (entry.outOfPocketAmount > 0)
          _DetailRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'هزینه از جیب',
            child: MoneyText(
              amountRial: entry.outOfPocketAmount,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (note.isNotEmpty)
          _DetailRow(
            icon: Icons.sticky_note_2_outlined,
            label: 'یادداشت',
            value: note,
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    showWorkEntryFormSheet(context, entry: entry),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('ویرایش'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(
                    color: theme.colorScheme.error.withValues(alpha: 0.5),
                  ),
                ),
                onPressed: () => _delete(context, ref),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('حذف'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _timeText(WorkEntry entry) {
    if (entry.startTime == null && entry.endTime == null) return 'ثبت نشده';
    final from = formatClockText(entry.startTime);
    final to = formatClockText(entry.endTime);
    final duration = shiftDuration(entry.startTime, entry.endTime);
    final extra = duration == null ? '' : ' (${formatDuration(duration)})';
    return 'از $from تا $to$extra';
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDialog(
      context,
      title: 'حذف این روزکار؟',
      message: 'این روزکار حذف می‌شود. تا چند لحظه می‌توانی برگردانی.',
      confirmLabel: 'حذف',
      destructive: true,
    );
    if (!ok) return;
    await ref.read(workEntryDaoProvider).delete(entry.id);
    if (!context.mounted) return;
    showUndoSnackBar(
      context,
      message: 'روزکار حذف شد.',
      onUndo: () => ref.read(workEntryDaoProvider).restore(entry),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.child,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: child ??
                  Text(
                    value ?? '—',
                    style: theme.textTheme.bodyMedium,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
