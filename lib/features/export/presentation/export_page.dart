import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/jalali_utils.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../shared/utils/file_actions.dart';
import '../../../shared/widgets/jalali_date_picker.dart';
import '../../../shared/widgets/section_card.dart';
import '../../employers/state/employer_providers.dart';
import '../domain/docx_writer.dart';
import '../domain/export_data.dart';
import '../domain/export_renderer.dart';
import '../state/export_providers.dart';

class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  bool _busy = false;

  /// Runs an export action and reports the result. The messenger is captured
  /// before the await so no context is used across an async gap.
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
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('خطا در خروجی گرفتن: $error'),
            backgroundColor: errorColor,
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(exportFilterProvider);
    final controller = ref.read(exportFilterProvider.notifier);
    final data = ref.watch(exportDataProvider);
    final employers = ref.watch(employersProvider).value ?? const [];
    final leaving = ref.watch(allEntriesProvider).hasValue;
    final theme = Theme.of(context);

    final file = renderExport(data, filter.format);

    return Scaffold(
      appBar: AppBar(title: const Text('خروجی گرفتن')),
      body: !leaving
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                SectionCard(
                  title: 'بازه گزارش',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final preset in ExportRangePreset.values)
                            ChoiceChip(
                              label: Text(preset.label),
                              selected: filter.preset == preset,
                              onSelected: (_) => controller.setPreset(preset),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _pickRange(filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.date_range_outlined,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${formatJalaliLong(filter.from)} '
                                  'تا ${formatJalaliLong(filter.to)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                'تغییر بازه',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'کارفرماها',
                  trailing: filter.allEmployers
                      ? null
                      : TextButton(
                          onPressed: controller.clearEmployers,
                          child: const Text('همه'),
                        ),
                  child: employers.isEmpty
                      ? Text(
                          'هنوز کارفرمایی ثبت نشده است.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('همه کارفرماها'),
                              selected: filter.allEmployers,
                              onSelected: (_) => controller.clearEmployers(),
                            ),
                            for (final employer in employers)
                              FilterChip(
                                avatar: CircleAvatar(
                                  backgroundColor: Color(employer.color),
                                  radius: 6,
                                ),
                                label: Text(employer.name),
                                selected:
                                    filter.employerIds.contains(employer.id),
                                onSelected: (_) =>
                                    controller.toggleEmployer(employer.id),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'قالب خروجی',
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: RadioGroup<ExportFormat>(
                    groupValue: filter.format,
                    onChanged: (value) {
                      if (value != null) controller.setFormat(value);
                    },
                    child: Column(
                      children: [
                        for (final format in ExportFormat.values)
                          RadioListTile<ExportFormat>(
                            value: format,
                            contentPadding: EdgeInsets.zero,
                            title: Text(format.label),
                            subtitle: Text(
                              format.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'پیش‌نمایش',
                  trailing: Text(
                    formatBytes(file.sizeInBytes),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        file.fileName,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (data.sections.isEmpty)
                        Text(
                          'در این بازه و با این فیلترها داده‌ای نیست. '
                          'بازه یا کارفرماها را تغییر دهید.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      else if (file.textPreview != null)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 240),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _previewText(file.textPreview!),
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.9,
                              ),
                            ),
                          ),
                        )
                      else
                        Text(
                          'فایل ورد با متن راست‌به‌چپ و جدول ساخته می‌شود. قلم سند '
                          'Vazirmatn است؛ اگر روی دستگاه خواننده نصب نباشد، '
                          'برنامه واژه‌پرداز یک قلم جایگزین مثل '
                          '«${DocxWriter.fallbackFont}» نشان می‌دهد.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.8,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy || data.sections.isEmpty
                            ? null
                            : () => _run(() async {
                                await shareBytes(
                                  fileName: file.fileName,
                                  bytes: file.bytes,
                                  mimeType: file.mimeType,
                                  subject: 'گزارش روزکار و حساب — دیپی',
                                );
                                return null;
                              }),
                        icon: const Icon(Icons.ios_share_rounded),
                        label: const Text('اشتراک‌گذاری'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy || data.sections.isEmpty
                            ? null
                            : () => _run(() async {
                                final path = await saveBytesAs(
                                  fileName: file.fileName,
                                  bytes: file.bytes,
                                  mimeType: file.mimeType,
                                  dialogTitle: 'ذخیره گزارش',
                                );
                                return path == null ? null : 'گزارش ذخیره شد.';
                              }),
                        icon: const Icon(Icons.save_alt_rounded),
                        label: const Text('ذخیره فایل'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'تعداد کارفرما در گزارش: '
                  '${toPersianDigits(data.sections.length)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }

  String _previewText(String source) {
    final lines = source.split('\n');
    if (lines.length <= 60) return source;
    return '${lines.take(60).join('\n')}\n…';
  }

  Future<void> _pickRange(ExportFilter filter) async {
    final from = await showJalaliDatePicker(
      context,
      initialDate: filter.from,
    );
    if (from == null || !mounted) return;
    final to = await showJalaliDatePicker(context, initialDate: filter.to);
    if (to == null || !mounted) return;
    ref.read(exportFilterProvider.notifier).setRange(from, to);
  }
}
