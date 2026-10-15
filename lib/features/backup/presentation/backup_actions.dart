import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../core/utils/persian_digits.dart';
import '../../settings/state/settings_providers.dart';
import '../data/backup_repository.dart';
import '../data/local_backup_service.dart';
import '../domain/backup_document.dart';
import '../state/backup_providers.dart';

/// Writes a backup right now and returns a short Persian success message.
Future<String> createLocalBackupNow(WidgetRef ref) async {
  final result = await ref.read(localBackupServiceProvider).createBackup();
  return 'پشتیبان ذخیره شد: ${result.fileName}';
}

/// Lets the user pick a JSON file and restores it. Returns a short message, or
/// null when the user cancelled.
Future<String?> restoreBackupFromFile(
  BuildContext context,
  WidgetRef ref,
) async {
  final picked = await FilePicker.pickFile(
    dialogTitle: 'انتخاب فایل پشتیبان',
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (picked == null) return null;

  final source = utf8.decode(await picked.readAsBytes(), allowMalformed: true);
  if (!context.mounted) return null;
  final document = BackupDocument.decode(source);
  final mode = await _askImportMode(context, document, 'فایل');
  if (mode == null) return null;

  final result = await ref
      .read(backupRepositoryProvider)
      .import(document: document, mode: mode);
  if (mode == ImportMode.replace && document.settings.isNotEmpty) {
    await ref
        .read(settingsControllerProvider.notifier)
        .applyImported(document.settings);
  }
  ref.invalidate(earliestActivityProvider);
  return 'بازگردانی انجام شد: ${result.summaryFa}';
}

Future<ImportMode?> _askImportMode(
  BuildContext context,
  BackupDocument document,
  String origin,
) {
  final counts =
      document.toJson()['counts'] as Map<String, Object?>? ?? const {};
  return showDialog<ImportMode>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        title: const Text('بازگردانی از فایل پشتیبان'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('منبع: $origin'),
            const SizedBox(height: 10),
            Text(
              'فایل شامل '
              '${toPersianDigits('${counts['employers'] ?? 0}')} کارفرما، '
              '${toPersianDigits('${counts['workEntries'] ?? 0}')} روزکار و '
              '${toPersianDigits('${counts['payments'] ?? 0}')} پرداخت است. '
              'تاریخ ساخت: ${formatJalaliLongIso(document.exportedAt)}',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
            ),
            const SizedBox(height: 16),
            for (final mode in ImportMode.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${mode.label}: ${mode.description}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.7,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(ImportMode.merge),
            child: const Text('ادغام'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(ImportMode.replace),
            child: const Text('جایگزینی کامل'),
          ),
        ],
      );
    },
  );
}
