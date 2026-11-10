import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/persian_digits.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../data/apk_update_installer.dart';
import '../domain/app_release.dart';
import '../state/update_providers.dart';

/// Shows the "new version" dialog: version, release notes and an install
/// button. The app downloads the APK, verifies it and asks Android's installer;
/// Android shows its own confirmation and the user stays in control.
Future<void> showUpdateDialog(BuildContext context, AppRelease release) {
  return showDialog<void>(
    context: context,
    builder: (_) => UpdateDialog(release: release),
  );
}

class UpdateDialog extends ConsumerStatefulWidget {
  const UpdateDialog({super.key, required this.release});

  final AppRelease release;

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog>
    with WidgetsBindingObserver {
  StreamSubscription<ApkInstallEvent>? _events;
  ApkInstallStage? _stage;
  int _percent = 0;
  String? _message;
  bool _starting = false;
  bool _permissionPending = false;

  bool get _working =>
      _starting ||
      _stage == ApkInstallStage.downloading ||
      _stage == ApkInstallStage.verifying ||
      _stage == ApkInstallStage.waiting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final installer = ref.read(apkUpdateInstallerProvider);
    _events = installer.events.listen(_onEvent);
    // Reopened while the native download is still running: show its state.
    final last = installer.lastEvent;
    if (last != null && _isCurrent(last)) {
      _stage = last.stage;
      _percent = last.percent;
      _message = last.message;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _events?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_permissionPending) return;
    _permissionPending = false;
    unawaited(_startIfAllowed());
  }

  bool _isCurrent(ApkInstallEvent event) =>
      event.version == null ||
      event.version == widget.release.version.toString();

  void _onEvent(ApkInstallEvent event) {
    if (!mounted || !_isCurrent(event)) return;
    setState(() {
      _stage = event.stage;
      _percent = event.percent;
      if (event.stage == ApkInstallStage.failed) {
        _message = event.message ?? 'دانلود یا نصب انجام نشد. دوباره تلاش کن.';
      }
    });
  }

  /// After returning from the system permission page, start only if it is now
  /// allowed; otherwise the user sees the dialog again and can retry.
  Future<void> _startIfAllowed() async {
    final installer = ref.read(apkUpdateInstallerProvider);
    if (await installer.canInstall() && mounted) {
      await _start();
    }
  }

  Future<void> _start() async {
    if (_starting || _working) return;
    final installer = ref.read(apkUpdateInstallerProvider);
    setState(() {
      _starting = true;
      _message = null;
      _stage = null;
    });

    if (!await installer.canInstall()) {
      if (!mounted) return;
      setState(() => _starting = false);
      final go = await _askInstallPermission();
      if (go == true) {
        _permissionPending = true;
        await installer.openInstallSettings();
      }
      return;
    }

    final started = await ref
        .read(updateControllerProvider.notifier)
        .installUpdate(widget.release);
    if (!mounted) return;
    if (!started) {
      setState(() {
        _starting = false;
        _stage = ApkInstallStage.failed;
        _message = 'شروع دانلود ممکن نشد. اتصال اینترنت را بررسی کن.';
      });
      return;
    }
    setState(() => _starting = false);
  }

  Future<bool?> _askInstallPermission() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('اجازه نصب لازم است'),
        content: const Text(
          'اندروید برای نصب نسخه تازه از دیپی، یک اجازه از تو می‌خواهد. '
          'در صفحه‌ای که باز می‌شود، «نصب برنامه‌های ناشناس» را برای دیپی روشن کن '
          'و برگرد. نصب را هم خود اندروید با یک پنجره تأیید می‌گیرد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('بعداً'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('رفتن به تنظیمات'),
          ),
        ],
      ),
    );
  }

  Future<void> _openInBrowser() async {
    final opened = await ref
        .read(updateControllerProvider.notifier)
        .openDownload(widget.release);
    if (!mounted) return;
    if (opened) {
      Navigator.of(context).pop();
    } else {
      showInfoSnackBar(context, 'باز کردن مرورگر ممکن نشد.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = widget.release.body.trim();

    return AlertDialog(
      icon: Icon(
        Icons.system_update_alt_rounded,
        size: 40,
        color: theme.colorScheme.primary,
      ),
      title: const Text('نسخه تازه هست'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'نسخه ${toPersianDigits(widget.release.version.toString())}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('تازه‌ها در این نسخه:', style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(notes, style: theme.textTheme.bodyMedium),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _Status(
              stage: _stage,
              percent: _percent,
              message: _message,
            ),
            if (!_working) ...[
              const SizedBox(height: 8),
              Text(
                'فایل از گیت‌هاب دانلود می‌شود و اندروید تأیید نصب را می‌پرسد. '
                'دیپی پیش از نصب، سازنده و امضای فایل را بررسی می‌کند.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _openInBrowser,
                  child: const Text('باز کردن صفحه انتشار در مرورگر'),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _starting ? null : () => Navigator.of(context).pop(),
          child: Text(_working ? 'بستن' : 'بعداً'),
        ),
        if (!_working)
          FilledButton.icon(
            onPressed: _starting ? null : _start,
            icon: const Icon(Icons.download_rounded),
            label: Text(
              _stage == ApkInstallStage.failed ? 'تلاش دوباره' : 'دانلود و نصب',
            ),
          ),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.stage, required this.percent, this.message});

  final ApkInstallStage? stage;
  final int percent;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (stage) {
      case ApkInstallStage.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: percent > 0 ? percent / 100 : null,
              minHeight: 8,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 8),
            Text(
              'در حال دانلود… ${toPersianDigits(percent)}٪',
              style: theme.textTheme.bodySmall,
            ),
          ],
        );
      case ApkInstallStage.verifying:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LinearProgressIndicator(minHeight: 8),
            const SizedBox(height: 8),
            Text('بررسی امضا و نسخه فایل…', style: theme.textTheme.bodySmall),
          ],
        );
      case ApkInstallStage.waiting:
        return Row(
          children: [
            Icon(Icons.verified_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'فایل سالم است. پنجره نصب اندروید را تأیید کن.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      case ApkInstallStage.failed:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message ?? 'نصب انجام نشد.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        );
      case ApkInstallStage.installed:
        return Text('نسخه تازه نصب شد.', style: theme.textTheme.bodyMedium);
      case null:
        return const SizedBox.shrink();
    }
  }
}
