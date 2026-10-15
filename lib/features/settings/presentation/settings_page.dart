import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../core/utils/pin_hash.dart';
import '../../../domain/enums.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/branding/dipi_logo.dart';
import '../../../shared/widgets/section_card.dart';
import '../../backup/presentation/backup_page.dart';
import '../../export/presentation/export_page.dart';
import '../../lock/presentation/pin_dialogs.dart';
import '../../lock/state/lock_providers.dart';
import '../domain/app_settings.dart';
import '../state/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsControllerProvider);
    final settings = asyncSettings.value ?? const AppSettings();
    final controller = ref.read(settingsControllerProvider.notifier);
    final theme = Theme.of(context);

    if (asyncSettings.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('تنظیمات')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SectionCard(
            title: 'ظاهر',
            child: RadioGroup<ThemeChoice>(
              groupValue: settings.themeChoice,
              onChanged: (value) {
                if (value != null) controller.setThemeChoice(value);
              },
              child: Column(
                children: [
                  for (final choice in ThemeChoice.values)
                    RadioListTile<ThemeChoice>(
                      value: choice,
                      title: Text(choice.label),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'واحد پول',
            child: Column(
              children: [
                RadioGroup<CurrencyUnit>(
                  groupValue: settings.currencyUnit,
                  onChanged: (value) {
                    if (value != null) controller.setCurrencyUnit(value);
                  },
                  child: Column(
                    children: [
                      for (final unit in CurrencyUnit.values)
                        RadioListTile<CurrencyUnit>(
                          value: unit,
                          title: Text(unit.label),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'مبالغ به صورت عدد صحیح ذخیره می‌شوند. تغییر واحد پول فقط '
                  'نمایش را عوض می‌کند و داده‌ها دست‌نخورده می‌مانند.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'پشتیبان‌گیری و خروجی',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('پشتیبان‌گیری و بازگردانی'),
                  subtitle: Text(
                    settings.lastBackupDate == null
                        ? 'هنوز پشتیبان نگرفته‌اید'
                        : 'آخرین پشتیبان: '
                              '${formatJalaliShort(settings.lastBackupDate!)}',
                  ),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BackupPage(),
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('خروجی گرفتن (txt / md / docx)'),
                  subtitle: const Text('گزارش روزکار و حساب برای بازه دلخواه'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ExportPage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SecurityCard(settings: settings),
          const SizedBox(height: 12),
          SectionCard(
            title: 'درباره دیپی',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: DipiMark(size: 64)),
                const SizedBox(height: 12),
                Text(
                  '${AppInfo.nameFa} (${AppInfo.nameEn})',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppInfo.taglineFa,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
                ),
                const SizedBox(height: 8),
                Text(
                  'کاملاً آفلاین. هیچ داده‌ای به سرور فرستاده نمی‌شود؛ تنها '
                  'ارتباط شبکه‌ای، پشتیبان‌گیری اختیاری در گوگل‌درایو است.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('نسخه'),
                    const Spacer(),
                    Text(toPersianDigits(AppInfo.version)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends ConsumerWidget {
  const _SecurityCard({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(settingsControllerProvider.notifier);
    final biometricSupported = ref.watch(biometricSupportProvider).value ?? false;
    final theme = Theme.of(context);

    Future<void> enableLock() async {
      final pin = await askNewPin(context);
      if (pin == null) return;
      final salt = generatePinSalt();
      await controller.setAppLock(
        enabled: true,
        pinHash: hashPin(pin, salt),
        pinSalt: salt,
        pinLength: pin.length,
      );
      if (context.mounted) {
        showInfoSnackBar(context, 'قفل برنامه روشن شد.');
      }
    }

    Future<void> disableLock() async {
      if (!await confirmCurrentPin(context, ref)) return;
      await controller.setAppLock(enabled: false);
      if (context.mounted) {
        showInfoSnackBar(context, 'قفل برنامه خاموش شد.');
      }
    }

    Future<void> changePin() async {
      if (!await confirmCurrentPin(context, ref)) return;
      if (!context.mounted) return;
      final pin = await askNewPin(context, title: 'رمز تازه');
      if (pin == null) return;
      final salt = generatePinSalt();
      await controller.setAppLock(
        enabled: true,
        pinHash: hashPin(pin, salt),
        pinSalt: salt,
        pinLength: pin.length,
      );
      if (context.mounted) showInfoSnackBar(context, 'رمز عوض شد.');
    }

    return SectionCard(
      title: 'امنیت',
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.appLockEnabled,
            onChanged: (value) => value ? enableLock() : disableLock(),
            title: const Text('قفل برنامه'),
            subtitle: Text(
              'هنگام باز کردن دیپی یک رمز عددی خواسته می‌شود.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (settings.appLockEnabled) ...[
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.password_rounded),
              title: const Text('تغییر رمز'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: changePin,
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.biometricEnabled,
              onChanged: biometricSupported
                  ? (value) => controller.setBiometricEnabled(value)
                  : null,
              title: const Text('باز کردن با اثر انگشت'),
              subtitle: Text(
                biometricSupported
                    ? 'در کنار رمز، اثر انگشت هم پیشنهاد می‌شود.'
                    : 'این دستگاه اثر انگشت ثبت‌شده‌ای ندارد.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
