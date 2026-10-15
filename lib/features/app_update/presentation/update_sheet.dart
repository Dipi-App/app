import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/persian_digits.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../data/apk_installer.dart';
import '../domain/update_format.dart';
import '../domain/update_phase.dart';
import '../state/update_controller.dart';
import '../state/update_providers.dart';

/// Opens the update modal. Uses its own sheet (not [showAppSheet]) so it does
/// not count as a form and block itself.
Future<void> showUpdateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxWidth: 620,
      maxHeight: MediaQuery.sizeOf(context).height * 0.92,
    ),
    builder: (_) => const UpdateSheet(),
  );
}

class UpdateSheet extends ConsumerWidget {
  const UpdateSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);
    final version = state.release?.version.toString() ?? '';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: switch (state.phase) {
        UpdatePhase.hidden => AppSheet(
          title: 'برنامه به‌روز است',
          child: const Text('نسخه تازه‌تری وجود ندارد.'),
        ),
        UpdatePhase.available => AppSheet(
          title: 'نسخه جدید هست',
          subtitle: 'نسخه $version',
          actions: [
            OutlinedButton(
              onPressed: () => _later(context, controller),
              child: const Text('بعداً'),
            ),
            FilledButton(
              onPressed: () => controller.startDownload(force: true),
              child: const Text('دانلود'),
            ),
          ],
          child: _AvailableBody(sizeLabel: formatUpdateSize(state.totalBytes)),
        ),
        UpdatePhase.downloading => AppSheet(
          title: 'نسخه جدید در حال دانلود است',
          subtitle: 'نسخه $version',
          actions: [
            OutlinedButton(
              onPressed: () => _cancel(context, controller),
              child: const Text('لغو دانلود'),
            ),
          ],
          child: _DownloadingBody(
            sizeLabel: formatUpdateSize(state.totalBytes),
            downloadedLabel: formatUpdateSize(state.receivedBytes),
            progress: state.progress,
            notes: state.release?.body ?? '',
          ),
        ),
        UpdatePhase.ready => AppSheet(
          title: 'نسخه جدید آماده نصب است',
          subtitle: 'نسخه $version',
          actions: [
            OutlinedButton(
              onPressed: () => _later(context, controller),
              child: const Text('بعداً'),
            ),
            FilledButton(
              onPressed: () => _install(context, ref),
              child: const Text('نصب نسخه جدید'),
            ),
          ],
          child: const _ReadyBody(),
        ),
        UpdatePhase.error => AppSheet(
          title: 'دانلود کامل نشد',
          subtitle: 'نسخه $version',
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('بستن'),
            ),
            FilledButton(
              onPressed: controller.retry,
              child: const Text('تلاش دوباره'),
            ),
          ],
          child: _ErrorBody(message: state.errorMessage),
        ),
      },
    );
  }

  void _later(BuildContext context, UpdateController controller) {
    controller.dismissModal();
    Navigator.of(context).maybePop();
  }

  Future<void> _cancel(
    BuildContext context,
    UpdateController controller,
  ) async {
    final ok = await confirmDialog(
      context,
      title: 'دانلود لغو شود؟',
      message: 'می‌توانی بعداً دوباره دانلود را شروع کنی.',
      confirmLabel: 'لغو دانلود',
      cancelLabel: 'ادامه بدهم',
    );
    if (!ok) return;
    controller.cancelDownload();
    if (context.mounted) Navigator.of(context).maybePop();
  }

  Future<void> _install(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(updateControllerProvider.notifier);
    var outcome = await controller.install();
    if (outcome == InstallOutcome.needsPermission && context.mounted) {
      final granted = await showInstallPermissionDialog(context, ref);
      if (granted && context.mounted) {
        outcome = await controller.install();
      }
    }
    if (outcome == InstallOutcome.started && context.mounted) {
      Navigator.of(context).maybePop();
    }
  }
}

class _AvailableBody extends StatelessWidget {
  const _AvailableBody({required this.sizeLabel});

  final String sizeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.system_update_alt_rounded,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'دانلود با اینترنت موبایل؟ حجم: $sizeLabel',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'اگر وای‌فای وصل کنی، خودش دانلود می‌کند و لازم نیست کاری کنی.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DownloadingBody extends StatelessWidget {
  const _DownloadingBody({
    required this.sizeLabel,
    required this.downloadedLabel,
    required this.progress,
    required this.notes,
  });

  final String sizeLabel;
  final String downloadedLabel;
  final double? progress;
  final String notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = progress == null ? null : formatUpdatePercent(progress!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            percent ?? '...',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(value: progress, minHeight: 18),
        ),
        const SizedBox(height: 12),
        Text(
          '$downloadedLabel از $sizeLabel',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        _Note(
          'می‌توانی برنامه را ببندی. دانلود از همان‌جا ادامه پیدا می‌کند.',
        ),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('تازه‌ها در این نسخه:', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _NotesBody(text: notes),
        ],
      ],
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 72,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        _Note('اطلاعات شما پاک نمی‌شود.'),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 64,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          message ?? 'دانلود انجام نشد.',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'اینترنت را بررسی کن و دکمه «تلاش دوباره» را بزن.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NotesBody extends StatelessWidget {
  const _NotesBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Text(text, style: theme.textTheme.bodyMedium),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Steps to allow "install unknown apps", then continues the install.
Future<bool> showInstallPermissionDialog(BuildContext context, WidgetRef ref) {
  return showDialog<bool>(
    context: context,
    builder: (_) =>
        _InstallPermissionDialog(installer: ref.read(apkInstallerProvider)),
  ).then((value) => value ?? false);
}

class _InstallPermissionDialog extends StatefulWidget {
  const _InstallPermissionDialog({required this.installer});

  final ApkInstaller installer;

  @override
  State<_InstallPermissionDialog> createState() =>
      _InstallPermissionDialogState();
}

class _InstallPermissionDialogState extends State<_InstallPermissionDialog>
    with WidgetsBindingObserver {
  bool _waiting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_waiting && state == AppLifecycleState.resumed && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('اجازه نصب لازم است'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.settings_applications_rounded,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'برای نصب نسخه جدید، این دو کار را انجام بده:',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          const _Step(index: 1, text: 'روی دکمه «باز کردن تنظیمات» بزن.'),
          const _Step(index: 2, text: 'گزینه «اجازه از این منبع» را روشن کن.'),
          const _Step(index: 3, text: 'برگرد و «ادامه بدهم» را بزن.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('بعداً'),
        ),
        FilledButton(
          onPressed: () async {
            setState(() => _waiting = true);
            await widget.installer.openInstallSettings();
          },
          child: const Text('باز کردن تنظیمات'),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              toPersianDigits(index),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
