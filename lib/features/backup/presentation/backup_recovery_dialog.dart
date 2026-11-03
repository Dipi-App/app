import 'package:flutter/material.dart';

import '../../../core/utils/jalali_utils.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../shared/widgets/section_card.dart';
import '../data/backup_recovery.dart';
import '../data/backup_repository.dart';

/// Asks for the one permission that lets a reinstall see the backups the
/// previous install left behind. Returns true when the user wants to grant it.
///
/// Android 11 hides files nobody owns any more, and there is no dialog for
/// this permission: the user has to turn it on in the system settings.
Future<bool> showBackupRecoveryAccessDialog(BuildContext context) async {
  final theme = Theme.of(context);

  final wantsAccess = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('دیدن فایل‌های نصب قبلی'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'اندروید ۱۱ به بعد فایل‌هایی که یک نصب قبلی جا گذاشته از دید '
            'برنامه‌ها مخفی می‌کند. دیپی برای دیدن آن‌ها به اجازه‌ی '
            '«مدیریت همه فایل‌ها» نیاز دارد.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
          ),
          const SizedBox(height: 8),
          Text(
            'بدون این اجازه، پشتیبان شما در پوشه‌ی «Documents/dipi» می‌ماند '
            'و دیپی نمی‌تواند آن را بخواند.',
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.7,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('بعداً'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('اجازه بده'),
        ),
      ],
    ),
  );
  return wantsAccess ?? false;
}

/// Offers the newest backup left on the device after a reinstall. Returns the
/// chosen [ImportMode], or null when the user declines.
Future<ImportMode?> showBackupRecoveryDialog(
  BuildContext context,
  RecoverableBackup backup,
) {
  final theme = Theme.of(context);
  final createdAt = backupRecoveryFileNameDate(backup.fileName);
  final when = createdAt == null ? '—' : formatJalaliLong(createdAt);

  return showDialog<ImportMode>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('پشتیبان در این گوشی پیدا شد'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'دیپی روی این گوشی داده‌ای ندارد، ولی یک پشتیبان از نصب '
            'قبلی روی این گوشی مانده است.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: when,
            child: Text(
              '${toPersianDigits('${backup.employers}')} کارفرما، '
              '${toPersianDigits('${backup.workEntries}')} روزکار و '
              '${toPersianDigits('${backup.payments}')} پرداخت',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '«ادغام» فقط چیزهای تازه را اضافه می‌کند. «جایگزینی کامل» '
            'هنوز کاری با داده‌های شما ندارد چون دیپی خالی است.',
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.7,
              color: theme.colorScheme.onSurfaceVariant,
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
          onPressed: () => Navigator.of(dialogContext).pop(ImportMode.replace),
          child: const Text('جایگزینی کامل'),
        ),
      ],
    ),
  );
}
