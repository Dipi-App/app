import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/help/help_page.dart';
import '../../../core/providers/app_info_providers.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../core/widgets/directional_icons.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../core/utils/pin_hash.dart';
import '../../../domain/enums.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../../../shared/branding/dipi_logo.dart';
import '../../../shared/widgets/section_card.dart';
import '../../app_update/domain/update_phase.dart';
import '../../app_update/presentation/update_sheet.dart';
import '../../app_update/state/update_controller.dart';
import '../../app_update/state/update_providers.dart';
import '../../backup/presentation/backup_page.dart';
import '../../export/presentation/export_page.dart';
import '../../lock/presentation/pin_dialogs.dart';
import '../../lock/state/lock_providers.dart';
import '../../onboarding/presentation/onboarding_page.dart';
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
                  trailing: const Icon(DirectionalIcons.forward),
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
                  trailing: const Icon(DirectionalIcons.forward),
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
            title: 'آموزش و راهنما',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('آموزش اولیه'),
                  subtitle: const Text('دوباره این چند اسلاید ساده را ببین'),
                  trailing: const Icon(DirectionalIcons.forward),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OnboardingPage(),
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('راهنمای کار با دیپی'),
                  subtitle: const Text('ثبت روزکار، پرداخت، حساب، پشتیبان و خروجی'),
                  trailing: const Icon(DirectionalIcons.forward),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const HelpPage()),
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: settings.voiceHintsEnabled,
                  onChanged: controller.setVoiceHintsEnabled,
                  title: const Text('خواندن راهنما با صدا'),
                  subtitle: const Text(
                    'در صفحه‌های مهم، دکمه بلندگو متن راهنما را می‌خواند.',
                  ),
                ),
              ],
            ),
          ),
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
                    Text(
                      toPersianDigits(
                        ref.watch(appVersionProvider).value ?? AppInfo.version,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const _UpdateSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateSection extends ConsumerWidget {
  const _UpdateSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoWifiOnly = ref.watch(settingsValueProvider).autoUpdateWifiOnly;
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final phase = ref.watch(updateControllerProvider.select((s) => s.phase));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: autoWifiOnly,
          onChanged: settingsController.setAutoUpdateWifiOnly,
          title: const Text('دانلود خودکار فقط با Wi-Fi'),
          subtitle: const Text(
            'اگر خاموش باشد، روی اینترنت موبایل هم خودش دانلود می‌کند.',
          ),
        ),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.system_update_alt_rounded),
          title: const Text('بررسی نسخه جدید'),
          subtitle: Text(_statusText(phase)),
          trailing: const Icon(DirectionalIcons.forward),
          onTap: () => _check(context, ref),
        ),
      ],
    );
  }

  String _statusText(UpdatePhase phase) => switch (phase) {
    UpdatePhase.ready => 'نسخه جدید آماده نصب است',
    UpdatePhase.downloading => 'در حال دانلود نسخه جدید',
    UpdatePhase.available => 'نسخه جدید هست',
    UpdatePhase.error => 'دانلود نسخه جدید ناموفق بود',
    UpdatePhase.hidden => 'از گیت‌هاب بررسی می‌شود',
  };

  Future<void> _check(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(updateControllerProvider.notifier);
    final outcome = await controller.checkForUpdates(manual: true);
    if (!context.mounted) return;
    switch (outcome) {
      case CheckOutcome.found:
        await showUpdateSheet(context);
      case CheckOutcome.upToDate:
        showInfoSnackBar(context, 'نسخه شما به‌روز است.');
      case CheckOutcome.busy:
        showInfoSnackBar(context, 'همین حالا مشغول دانلود است.');
      case CheckOutcome.skipped:
      case CheckOutcome.offLine:
      case CheckOutcome.rateLimited:
        showInfoSnackBar(
          context,
          'بررسی انجام نشد. اینترنت را بررسی کن و دوباره بزن.',
        );
    }
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
              trailing: const Icon(DirectionalIcons.forward),
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
