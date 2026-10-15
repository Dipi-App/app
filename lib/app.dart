import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_info.dart';
import 'core/theme/app_theme.dart';
import 'domain/enums.dart';
import 'features/settings/state/settings_providers.dart';
import 'presentation/app_gate.dart';

class DipiApp extends ConsumerWidget {
  const DipiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeChoice = ref.watch(
      settingsControllerProvider.select(
        (settings) => settings.value?.themeChoice ?? ThemeChoice.system,
      ),
    );

    return MaterialApp(
      title: AppInfo.storeTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (themeChoice) {
        ThemeChoice.system => ThemeMode.system,
        ThemeChoice.light => ThemeMode.light,
        ThemeChoice.dark => ThemeMode.dark,
      },
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const AppGate(),
    );
  }
}
