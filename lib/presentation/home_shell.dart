import 'package:flutter/material.dart';

import '../core/widgets/floating_nav_bar.dart';
import '../features/backup/presentation/widgets/backup_reminder_banner.dart';
import '../features/calendar/presentation/calendar_page.dart';
import '../features/calendar/presentation/widgets/work_entry_form_sheet.dart';
import '../features/employers/presentation/employers_page.dart';
import '../features/payments/presentation/payments_page.dart';
import '../features/stats/presentation/stats_page.dart';
import '../shared/utils/motion.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  int _previousIndex = 0;
  late final AnimationController _switch;

  static const _tabs = [
    FloatingNavItem(
      label: 'تقویم',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      semanticLabel: 'تقویم روزکارها',
    ),
    FloatingNavItem(
      label: 'کارفرماها',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      semanticLabel: 'کارفرماها',
    ),
    FloatingNavItem(
      label: 'پرداخت‌ها',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      semanticLabel: 'پرداخت‌ها',
    ),
    FloatingNavItem(
      label: 'آمار',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
      semanticLabel: 'آمار و حساب',
    ),
  ];

  static const _pages = [
    CalendarPage(),
    EmployersPage(),
    PaymentsPage(),
    StatsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _switch = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1,
    );
  }

  @override
  void dispose() {
    _switch.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _previousIndex = _index;
      _index = index;
    });
    if (reduceMotion(context)) {
      _switch.value = 1;
    } else {
      _switch.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotion(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    var direction = _index >= _previousIndex ? 1.0 : -1.0;
    if (rtl) direction = -direction;

    final curved = CurvedAnimation(parent: _switch, curve: Curves.easeOutCubic);
    final opacity = Tween<double>(begin: 0.35, end: 1).animate(curved);
    final slide = Tween<Offset>(
      begin: Offset(reduced ? 0 : direction * 0.04, 0),
      end: Offset.zero,
    ).animate(curved);

    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          const BackupReminderBanner(),
          Expanded(
            child: FadeTransition(
              opacity: opacity,
              child: SlideTransition(
                position: slide,
                child: IndexedStack(index: _index, children: _pages),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: _index,
        items: _tabs,
        onSelected: _select,
        primaryAction: FloatingNavPrimaryAction(
          icon: Icons.add_rounded,
          label: 'روزکار',
          semanticLabel: 'افزودن روزکار تازه',
          onTap: () => showWorkEntryFormSheet(context),
        ),
      ),
    );
  }
}
