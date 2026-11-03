import 'dart:async';

import 'package:dipi_documents/dipi_documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/help/coach_mark.dart';
import '../features/backup/data/backup_recovery.dart';
import '../features/backup/data/local_backup_service.dart';
import '../features/backup/presentation/backup_recovery_dialog.dart';
import '../features/backup/state/backup_providers.dart';
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
  bool _recoveryChecked = false;
  bool _recoveryRunning = false;
  bool _waitingForFilesAccess = false;
  bool _accessDialogShown = false;
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
    if (state == AppLifecycleState.resumed && _waitingForFilesAccess) {
      _waitingForFilesAccess = false;
      unawaited(_afterFilesAccessScreen());
    }
  }

  /// Called after the user leaves the system "All files access" page. The look
  /// is re-armed rather than closed: a running process cannot always see a
  /// permission granted while it was up, and ending the offer on that answer
  /// would throw away the only copy of the data.
  Future<void> _afterFilesAccessScreen() async {
    // Not while the lock screen is up: unlocking rebuilds the gate, which runs
    // this on its own.
    if (ref.read(appLockProvider)) return;
    _recoveryChecked = false;
    await _maybeOfferRecovery(afterGrant: true);
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

  /// Offers a backup left behind by an earlier install, once.
  /// Like the automatic backup, this must never block or bother the user.
  Future<void> _maybeOfferRecovery({bool afterGrant = false}) async {
    // A rebuild can post this while the check after the settings page is still
    // running, so keep the two from racing into two dialogs.
    if (_recoveryChecked || _recoveryRunning) return;
    _recoveryRunning = true;
    try {
      final recovery = ref.read(backupRecoveryServiceProvider);
      final settings = ref.read(settingsValueProvider);
      final rows = await ref.read(backupRepositoryProvider).rowCount();
      if (!shouldOfferBackupRecovery(
        onboardingSeen: settings.onboardingSeen,
        ledgerRowCount: rows,
        recoveryOffered: await recovery.alreadyOffered(),
      )) {
        // A first install is still inside onboarding here, so this stays open
        // and runs again when onboarding flips the setting.
        return;
      }

      // Conditions are met: this is the one and only look.
      _recoveryChecked = true;
      await ref
          .read(oneTimeDialogQueueProvider)
          .show(() => _runOffer(recovery, afterGrant: afterGrant));
    } catch (_) {
      // Unreadable files or a lost permission simply mean no offer.
    } finally {
      _recoveryRunning = false;
    }
  }

  /// The offer itself, held with the home screen to itself so the first-use
  /// tips cannot stack on top of it.
  Future<void> _runOffer(
    BackupRecoveryService recovery, {
    required bool afterGrant,
  }) async {
    final backup = await recovery.findRecoverableBackup();
    if (!mounted) return;

    if (backup == null) {
      // Android 11 and newer hide the files an earlier install left behind —
      // from a MediaStore query, from the File API and from the system picker
      // alike. Only "All files access" reaches them, and the user has to turn
      // that on in the system settings.
      if (await DipiDocuments.hasAllFilesAccess()) {
        // The platform applies that permission to a process when it starts, so
        // the install that has just been granted still cannot see the folder.
        // Asking again would loop; a restart is what actually changes things.
        if (afterGrant) {
          _showMessage('اجازه داده شد. برای دیدن فایل‌ها، دیپی را دوباره باز کنید.');
        }
        return;
      }
      if (_accessDialogShown) {
        // Asked once already in this launch. The grant only reaches a process
        // started after it, so a second dialog cannot change the answer.
        _showMessage('برای دیدن فایل‌ها، دیپی را دوباره باز کنید.');
        return;
      }
      if (!mounted) return;
      _accessDialogShown = true;
      final wantsAccess = await showBackupRecoveryAccessDialog(context);
      if (!wantsAccess) {
        await recovery.markOffered();
        return;
      }
      _waitingForFilesAccess = true;
      if (!await DipiDocuments.openAllFilesSettings()) {
        await recovery.markOffered();
      }
      return;
    }

    final mode = await showBackupRecoveryDialog(context, backup);
    if (mode == null) {
      await recovery.markOffered();
      return;
    }
    final result = await recovery.restore(backup, mode);
    if (!mounted) return;
    _showMessage('بازیابی انجام شد: ${result.summaryFa}');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final locked = ref.watch(appLockProvider);

    final showError = settings.hasError && _minimumElapsed;
    final ready = settings.hasValue && _minimumElapsed && !showError;
    if (ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoBackup());
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOfferRecovery());
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
