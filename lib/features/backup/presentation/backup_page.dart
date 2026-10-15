import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../shared/utils/file_actions.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/widgets/section_card.dart';
import '../../settings/state/settings_providers.dart';
import '../data/backup_repository.dart';
import '../data/drive_backup_service.dart';
import '../domain/backup_document.dart';
import '../state/backup_providers.dart';

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
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: errorColor,
            duration: const Duration(seconds: 8),
          ),
        );
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('$error'),
            backgroundColor: errorColor,
            duration: const Duration(seconds: 8),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Map<String, String>> _settingsMap() async =>
      ref.read(settingsValueProvider).toMap();

  Future<void> _markBackedUp() =>
      ref.read(settingsControllerProvider.notifier).setLastBackupAt(
        DateTime.now(),
      );

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsValueProvider);
    final session = ref.watch(driveSessionProvider);
    final driveInfo = ref.watch(driveBackupInfoProvider);
    final service = ref.watch(driveBackupServiceProvider);
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
            title: 'پشتیبان محلی',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'یک فایل JSON با همه کارفرماها، روزکارها و پرداخت‌ها. '
                  'می‌توانید آن را در گوگل‌درایو، رایانه یا پیام‌رسان نگه دارید.',
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
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _restoreFromFile,
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('بازگردانی از فایل'),
                ),
                const SizedBox(height: 8),
                Text(
                  'نام فایل: ${AppInfo.backupFileName(DateTime.now())}',
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'گوگل درایو',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!service.isConfigured)
                  _InfoNote(
                    icon: Icons.key_outlined,
                    text: 'برای فعال شدن پشتیبان‌گیری گوگل‌درایو، اول شناسه '
                        'کلاینت OAuth را بسازید (راهنما در پایین همین صفحه و در '
                        'AGENTS.md). تا آن زمان این بخش غیرفعال است.',
                  )
                else
                  switch (session) {
                    AsyncValue(:final value?) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AccountRow(
                          email: value.email,
                          onSignOut: _busy
                              ? null
                              : () => _run(() async {
                                  await ref
                                      .read(driveSessionProvider.notifier)
                                      .signOut();
                                  return 'از حساب گوگل خارج شدید.';
                                }),
                        ),
                        const SizedBox(height: 12),
                        _DriveStatus(info: driveInfo.value),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _busy ? null : _uploadToDrive,
                                icon: const Icon(Icons.cloud_upload_outlined),
                                label: const Text('پشتیبان به درایو'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _busy || driveInfo.value == null
                                    ? null
                                    : _restoreFromDrive,
                                icon: const Icon(Icons.cloud_download_outlined),
                                label: const Text('بازگردانی از درایو'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    AsyncValue(hasError: true) => _InfoNote(
                      icon: Icons.error_outline_rounded,
                      text: 'ورود به گوگل ناموفق بود. دوباره تلاش کنید.',
                    ),
                    AsyncValue(isLoading: true) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    _ => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'برای پشتیبان‌گیری در فضای خصوصی خودتان وارد حساب '
                          'گوگل شوید. دیپی فقط به پوشه پنهان خودش دسترسی دارد و '
                          'بقیه درایو شما را نمی‌بیند.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _run(() async {
                                  final account = await ref
                                      .read(driveSessionProvider.notifier)
                                      .signIn();
                                  ref.invalidate(driveBackupInfoProvider);
                                  return 'وارد شدید: ${account.email}';
                                }),
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('ورود با گوگل'),
                        ),
                      ],
                    ),
                  },
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: settings.autoBackupEnabled,
                  onChanged: service.isConfigured
                      ? (value) => ref
                            .read(settingsControllerProvider.notifier)
                            .setAutoBackup(value)
                      : null,
                  title: const Text('پشتیبان‌گیری خودکار'),
                  subtitle: Text(
                    'هنگام باز شدن برنامه، اگر بیش از یک روز از آخرین پشتیبان '
                    'گذشته باشد، یک نسخه بی‌صدا در گوگل‌درایو ساخته می‌شود.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.7,
                    ),
                  ),
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
          const SizedBox(height: 12),
          const _SetupGuide(),
        ],
      ),
    );
  }

  Future<String?> _shareBackup() async {
    final json = await ref
        .read(backupRepositoryProvider)
        .exportJson(settings: await _settingsMap());
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
        .exportJson(settings: await _settingsMap());
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

  Future<String?> _restoreFromFile() async {
    final result = await FilePicker.pickFile(
      dialogTitle: 'انتخاب فایل پشتیبان',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null) return null;
    final source = utf8.decode(await result.readAsBytes(), allowMalformed: true);
    return _applyImport(BackupDocument.decode(source), origin: 'فایل');
  }

  Future<String?> _restoreFromDrive() async {
    final source = await ref.read(driveBackupServiceProvider).download();
    ref.invalidate(driveBackupInfoProvider);
    return _applyImport(BackupDocument.decode(source), origin: 'گوگل‌درایو');
  }

  Future<String?> _applyImport(
    BackupDocument document, {
    required String origin,
  }) async {
    final mode = await _askImportMode(document, origin);
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
    BackupDocument document,
    String origin,
  ) async {
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

  Future<String?> _uploadToDrive() async {
    final json = await ref
        .read(backupRepositoryProvider)
        .exportJson(settings: await _settingsMap());
    final info = await ref.read(driveBackupServiceProvider).upload(json);
    await _markBackedUp();
    ref.invalidate(driveBackupInfoProvider);
    return 'پشتیبان در گوگل‌درایو ذخیره شد '
        '(${formatBytes(info.sizeInBytes)}).';
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
                            '${days != null && days > 0 ? ' ($days روز پیش)' : ''}',
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

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.email, this.onSignOut});

  final String email;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Icon(Icons.account_circle_outlined),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            email,
            textDirection: TextDirection.ltr,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        TextButton(
          onPressed: onSignOut,
          child: const Text('خروج'),
        ),
      ],
    );
  }
}

class _DriveStatus extends StatelessWidget {
  const _DriveStatus({required this.info});

  final DriveBackupInfo? info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = info;
    return Text(
      value == null
          ? 'در گوگل‌درایو هنوز پشتیبانی نیست.'
          : 'آخرین پشتیبان درایو: ${formatJalaliLong(value.modifiedAt)}'
                ' · ${formatBytes(value.sizeInBytes)}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupGuide extends StatelessWidget {
  const _SetupGuide();

  static const List<String> steps = [
    'در console.cloud.google.com یک پروژه بسازید (یا پروژه موجود را انتخاب کنید).',
    'از بخش APIs & Services → Library، سرویس «Google Drive API» را Enable کنید.',
    'در APIs & Services → OAuth consent screen، نوع External را انتخاب و '
        'اسکرین را پر کنید. در Scopes فقط '
        '«.../auth/drive.appdata» را اضافه کنید و در Test users حساب گوگل '
        'خودتان را اضافه کنید (در حالت Testing همین کافی است).',
    'در APIs & Services → Credentials دو کلاینت بسازید: یکی «Android» و یکی '
        '«Web application».',
    'برای کلاینت Android، نام پکیج (dipiAppId در android/gradle.properties) و '
        'اثر انگشت SHA-1 کلید امضا را وارد کنید. SHA-1 را با این دستور بگیرید:',
    'keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android',
    'برای کلاینت Web لازم به Redirect URI نیست؛ فقط Client ID آن را کپی کنید.',
    'برنامه را با شناسه کلاینت Web بسازید:',
    'flutter build apk --dart-define=DIPI_GOOGLE_SERVER_CLIENT_ID=XXXX.apps.googleusercontent.com',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'راه‌اندازی گوگل‌درایو (یک‌بار برای همیشه)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'این کارها را باید خودتان در Google Cloud انجام دهید؛ کد برنامه '
            'بدون آن‌ها کار می‌کند و فقط بخش گوگل‌درایو غیرفعال می‌ماند.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.8,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < steps.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${toPersianDigits(index + 1)}.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      steps[index],
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.8,
                        fontFamily:
                            steps[index].startsWith('flutter') ||
                                steps[index].startsWith('keytool')
                            ? 'monospace'
                            : null,
                      ),
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
