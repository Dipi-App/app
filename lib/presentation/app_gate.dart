import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/backup/data/local_backup_service.dart';
import '../features/lock/presentation/lock_screen.dart';
import '../features/lock/state/lock_providers.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/settings/state/settings_providers.dart';
import '../features/splash/presentation/splash_page.dart';
import '../shared/utils/motion.dart';
import 'home_shell.dart';

class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate>
    with WidgetsBindingObserver {
  static const _minimumSplash = Duration(milliseconds: 1100);

  bool _minimumElapsed = false;
  bool _autoBackupChecked = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer(_minimumSplash, () {
      if (mounted) setState(() => _minimumElapsed = true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Leaving the app re-arms the lock so the next look at the screen needs the
    // PIN (or the fingerprint) again.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(appLockProvider.notifier).lock();
    }
  }

  /// Writes a local backup on start when the last one is over 12 hours old.
  /// The 12-hour periodic worker does the same while the app is closed.
  Future<void> _maybeAutoBackup() async {
    if (_autoBackupChecked) return;
    _autoBackupChecked = true;
    final settings = ref.read(settingsValueProvider);
    final due = isAutoBackupDue(
      now: DateTime.now(),
      lastBackup: settings.lastBackupDate,
    );
    if (!due) return;

    try {
      await ref.read(localBackupServiceProvider).createBackup();
    } catch (_) {
      // Automatic backup must never bother the user; it is retried next time.
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final locked = ref.watch(appLockProvider);

    final showError = settings.hasError && _minimumElapsed;
    final ready = settings.hasValue && _minimumElapsed && !showError;
    if (ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoBackup());
    }

    final Widget child;
    if (showError) {
      child = SplashPage(
        key: const ValueKey('error'),
        errorMessage: 'بارگذاری تنظیمات با خطا روبه‌رو شد.',
        onRetry: () => ref.invalidate(settingsControllerProvider),
      );
    } else if (ready && locked) {
      child = const LockScreen(key: ValueKey('lock'));
    } else if (ready && !settings.requireValue.onboardingSeen) {
      child = const OnboardingPage(key: ValueKey('onboarding'));
    } else if (ready) {
      child = const HomeShell(key: ValueKey('home'));
    } else {
      child = const SplashPage(key: ValueKey('splash'));
    }

    return AnimatedSwitcher(
      duration: reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 450),
      child: child,
    );
  }
}
