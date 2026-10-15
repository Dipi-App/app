import 'package:flutter/material.dart';

import '../features/backup/presentation/widgets/backup_reminder_banner.dart';
import '../features/calendar/presentation/calendar_page.dart';
import '../features/employers/presentation/employers_page.dart';
import '../features/payments/presentation/payments_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/stats/presentation/stats_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _destinations = [
    _Destination(label: 'تقویم', icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month),
    _Destination(label: 'کارفرماها', icon: Icons.people_outline, selectedIcon: Icons.people),
    _Destination(label: 'پرداخت‌ها', icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long),
    _Destination(label: 'آمار', icon: Icons.insights_outlined, selectedIcon: Icons.insights),
    _Destination(label: 'تنظیمات', icon: Icons.settings_outlined, selectedIcon: Icons.settings),
  ];

  static const _pages = [
    CalendarPage(),
    EmployersPage(),
    PaymentsPage(),
    StatsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const BackupReminderBanner(),
          Expanded(child: IndexedStack(index: _index, children: _pages)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
