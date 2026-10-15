import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../domain/enums.dart';
import '../../../shared/widgets/section_card.dart';
import '../domain/app_settings.dart';
import '../state/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsControllerProvider);
    final settings = asyncSettings.value ?? const AppSettings();
    final controller = ref.read(settingsControllerProvider.notifier);

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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.7,
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
                Text(
                  '${AppInfo.nameFa} (${AppInfo.nameEn})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppInfo.taglineFa,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
          const SizedBox(height: 12),
          SectionCard(
            title: 'پشتیبان‌گیری و امنیت',
            child: Column(
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.backup_outlined),
                  title: Text('پشتیبان‌گیری محلی و گوگل‌درایو'),
                  subtitle: Text('در گام‌های بعدی فعال می‌شود'),
                ),
                const Divider(),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.lock_outline),
                  title: Text('قفل برنامه'),
                  subtitle: Text('رمز و اثر انگشت — در گام‌های بعدی فعال می‌شود'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
