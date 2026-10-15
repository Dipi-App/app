import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/state/settings_providers.dart';
import '../features/splash/presentation/splash_page.dart';
import '../shared/utils/motion.dart';
import 'home_shell.dart';

class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  static const _minimumSplash = Duration(milliseconds: 1100);

  bool _minimumElapsed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_minimumSplash, () {
      if (mounted) setState(() => _minimumElapsed = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);

    final showError = settings.hasError && _minimumElapsed;
    final showApp = settings.hasValue && _minimumElapsed && !showError;

    final Widget child;
    if (showError) {
      child = SplashPage(
        key: const ValueKey('error'),
        errorMessage: 'بارگذاری تنظیمات با خطا روبه‌رو شد.',
        onRetry: () => ref.invalidate(settingsControllerProvider),
      );
    } else if (showApp) {
      child = const HomeShell(key: ValueKey('home'));
    } else {
      child = const SplashPage(key: ValueKey('splash'));
    }

    return AnimatedSwitcher(
      duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 450),
      child: child,
    );
  }
}
