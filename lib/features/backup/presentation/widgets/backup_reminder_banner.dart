import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/persian_digits.dart';
import '../../../settings/state/settings_providers.dart';
import '../../state/backup_providers.dart';
import '../backup_page.dart';

/// Slim banner shown across the app when the ledger has never been backed up,
/// or the last backup is older than 30 days. Dismissing it snoozes for 3 days.
class BackupReminderBanner extends ConsumerWidget {
  const BackupReminderBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(backupReminderProvider)) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final lastBackup = ref.watch(settingsValueProvider).lastBackupDate;
    final days = lastBackup == null
        ? null
        : DateTime.now().difference(lastBackup).inDays;
    final message = lastBackup == null
        ? 'هنوز از داده‌هایتان پشتیبان نگرفته‌اید.'
        : '${toPersianDigits(days)} روز از آخرین پشتیبان‌گیری می‌گذرد.';

    return Material(
      color: theme.colorScheme.tertiaryContainer,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: () => _openBackup(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              children: [
                Icon(
                  Icons.backup_outlined,
                  size: 20,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _openBackup(context),
                  child: const Text('پشتیبان بگیر'),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'بعداً',
                  onPressed: () => ref
                      .read(settingsControllerProvider.notifier)
                      .setLastBackupReminderAt(DateTime.now()),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openBackup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BackupPage()),
    );
  }
}
