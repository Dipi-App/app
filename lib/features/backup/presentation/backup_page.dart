import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../shared/utils/file_actions.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/section_card.dart';
import '../../settings/state/settings_providers.dart';
import '../data/local_backup_service.dart';
import '../domain/backup_document.dart';
import '../state/backup_providers.dart';
import 'backup_actions.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _busy = false;

  Future<void> _run(Future<String?> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    setState(() => _busy = true);
    try {
      final message = await action();
      if (message != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    } on BackupFormatException catch (error) {
      _showError(messenger, errorColor, error.message);
    } on LocalBackupException catch (error) {
      _showError(messenger, errorColor, error.message);
    } catch (error) {
      _showError(messenger, errorColor, '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(
    ScaffoldMessengerState messenger,
    Color color,
    String message,
  ) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 8),
        ),
      );
  }

  Future<void> _markBackedUp() =>
      ref.read(settingsControllerProvider.notifier).setLastBackupAt(
        DateTime.now(),
      );

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsValueProvider);
    final theme = Theme.of(context);
    final lastBackup = settings.lastBackupDate;

    return Scaffold(
      appBar: AppBar(title: const Text('پشتیبان‌گیری')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _StatusCard(lastBackup: lastBackup),
          const SizedBox(height: 12),
          SectionCard(
            title: 'پشتیبان خودکار',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'هر ۱۲ ساعت، خودِ برنامه یک نسخه از همه اطلاعات را در پوشه '
                  '«Documents/dipi» گوشی می‌سازد. بدون اینترنت و بدون اجازه '
                  'اضافه. فقط ۱۴ نسخه‌ی آخر نگه داشته می‌شود.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _busy ? null : () => _run(() => createLocalBackupNow(ref)),
                  icon: const Icon(Icons.backup_outlined),
                  label: const Text('پشتیبان‌گیری الان'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() => restoreBackupFromFile(context, ref)),
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('بازگردانی از فایل'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'خروجی دستی فایل',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'یک فایل JSON با همه کارفرماها، روزکارها و پرداخت‌ها. '
                  'می‌توانید آن را در رایانه یا پیام‌رسان نگه دارید.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _shareBackup,
                        icon: const Icon(Icons.ios_share_rounded),
                        label: const Text('اشتراک‌گذاری'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _saveBackup,
                        icon: const Icon(Icons.save_alt_rounded),
                        label: const Text('ذخیره فایل'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'خطر',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'همه کارفرماها، روزکارها و پرداخت‌ها پاک می‌شوند. '
                  'این کار برگشت‌پذیر نیست؛ اول پشتیبان بگیرید.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _deleteEverything,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('پاک کردن همه داده‌ها'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _shareBackup() async {
    final json = await ref
        .read(backupRepositoryProvider)
        .exportJson(settings: ref.read(settingsValueProvider).toMap());
    final fileName = AppInfo.backupFileName(DateTime.now());
    await shareBytes(
      fileName: fileName,
      bytes: utf8.encode(json),
      mimeType: 'application/json',
      subject: 'پشتیبان ${AppInfo.nameFa}',
    );
    await _markBackedUp();
    return 'فایل پشتیبان آماده شد.';
  }

  Future<String?> _saveBackup() async {
    final json = await ref
        .read(backupRepositoryProvider)
        .exportJson(settings: ref.read(settingsValueProvider).toMap());
    final fileName = AppInfo.backupFileName(DateTime.now());
    final path = await saveBytesAs(
      fileName: fileName,
      bytes: utf8.encode(json),
      mimeType: 'application/json',
      dialogTitle: 'ذخیره پشتیبان',
    );
    if (path == null) return null;
    await _markBackedUp();
    return 'پشتیبان ذخیره شد.';
  }

  Future<String?> _deleteEverything() async {
    final confirmed = await confirmDialog(
      context,
      title: 'همه داده‌ها پاک شود؟',
      message: 'همه کارفرماها، روزکارها و پرداخت‌ها حذف می‌شوند. '
          'این کار برگشت‌پذیر نیست.',
      confirmLabel: 'پاک کن',
      destructive: true,
    );
    if (!confirmed) return null;
    await ref.read(backupRepositoryProvider).deleteEverything();
    return 'همه داده‌ها پاک شد.';
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.lastBackup});

  final DateTime? lastBackup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final days = lastBackup == null ? null : now.difference(lastBackup!).inDays;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lastBackup == null || (days ?? 0) > 30
            ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.45)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            lastBackup == null
                ? Icons.warning_amber_rounded
                : Icons.verified_outlined,
            color: lastBackup == null
                ? theme.colorScheme.tertiary
                : const Color(0xFF2E7D6F),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'آخرین پشتیبان',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastBackup == null
                      ? 'تا حالا پشتیبان نگرفته‌اید'
                      : '${formatJalaliLong(lastBackup!)}'
                            '${days != null && days > 0 ? ' (${toPersianDigits(days)} روز پیش)' : ''}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
