import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/persian_digits.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../domain/app_release.dart';
import '../state/update_providers.dart';

/// Shows the "new version" dialog: version, release notes and a button that
/// opens the APK download in the system browser. Nothing is downloaded or
/// installed by the app itself.
Future<void> showUpdateDialog(BuildContext context, AppRelease release) {
  return showDialog<void>(
    context: context,
    builder: (_) => UpdateDialog(release: release),
  );
}

class UpdateDialog extends ConsumerWidget {
  const UpdateDialog({super.key, required this.release});

  final AppRelease release;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notes = release.body.trim();

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
              'نسخه ${toPersianDigits(release.version.toString())}',
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
            Text(
              'برای دانلود، دکمه پایین را بزن. مرورگر باز می‌شود و فایل را از گیت‌هاب می‌گیری.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('بعداً'),
        ),
        FilledButton.icon(
          onPressed: () => _open(context, ref),
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('دانلود از گیت‌هاب'),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final opened = await ref
        .read(updateControllerProvider.notifier)
        .openDownload(release);
    if (!context.mounted) return;
    if (opened) {
      Navigator.of(context).pop();
    } else {
      showInfoSnackBar(context, 'باز کردن مرورگر ممکن نشد.');
    }
  }
}
