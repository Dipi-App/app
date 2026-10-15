import 'package:flutter/material.dart';

import '../../features/settings/presentation/settings_page.dart';

/// Opens the settings screen. Settings is not a tab of the floating bar
/// anymore (the center slot is reserved for the "add workday" action), so this
/// gear is offered on every top-level screen instead.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'تنظیمات',
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
      ),
    );
  }
}
