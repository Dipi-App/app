import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/jalali_utils.dart';
import '../../../core/utils/time_utils.dart';
import '../../../shared/utils/motion.dart';
import '../../../shared/widgets/count_up_text.dart';
import '../../../shared/widgets/money_text.dart';
import '../state/calendar_providers.dart';
import 'widgets/day_cell.dart';
import 'widgets/day_sheet.dart';

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

  @override
  void initState() {
    super.initState();
    _baseMonth = ref.read(visibleMonthProvider);
    _selected = dateOnly(DateTime.now());
    _controller = PageController(initialPage: _basePage);
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
    return toJalali(_baseMonth).addMonths(page - _basePage).withDay(1).toDateTime();
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

  Future<void> _openDay(DateTime day) async {
    setState(() => _selected = dateOnly(day));
    await showDaySheet(context, day);
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(visibleMonthProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => _goToMonth(previousJalaliMonth(month)),
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'ماه قبل',
        ),
        title: Text(formatJalaliMonthYear(month)),
        actions: [
          IconButton(
            onPressed: () => _goToMonth(nextJalaliMonth(month)),
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'ماه بعد',
          ),
          IconButton(
            onPressed: () => _goToMonth(DateTime.now()),
            icon: const Icon(Icons.today_rounded),
            tooltip: 'امروز',
          ),
        ],
      ),
      body: Column(
        children: [
          const _WeekdayHeader(),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (page) =>
                  ref.read(visibleMonthProvider.notifier).goTo(_monthForPage(page)),
              itemBuilder: (context, page) => _MonthGrid(
                month: _monthForPage(page),
                selected: _selected,
                onDayTap: _openDay,
              ),
            ),
          ),
          const _MonthSummary(),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          for (final label in jalaliWeekdayShort)
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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

    final grid = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          for (var row = 0; row < rows; row++)
            Expanded(
              child: Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: _gridCell(
                        cells[row * 7 + col],
                        colorsByDay,
                        pendingDays,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );

    return grid;
  }

  Widget _gridCell(
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

class _MonthSummary extends ConsumerWidget {
  const _MonthSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(visibleMonthProvider);
    final totals = ref.watch(monthTotalsProvider(jalaliMonthKey(month)));
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _SummaryItem(
            label: 'روز کاری',
            count: totals.dayCount,
          ),
          _SummaryItem(
            label: 'ساعت',
            value: formatHours(totals.hours),
          ),
          _SummaryItem(
            label: 'دستمزد',
            valueWidget: MoneyText(
              amountRial: totals.wageRial,
              animate: true,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E7D6F),
              ),
            ),
          ),
          if (totals.pendingCount > 0)
            _SummaryItem(
              label: 'در انتظار',
              count: totals.pendingCount,
            ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    this.value,
    this.count,
    this.valueWidget,
  });

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
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
