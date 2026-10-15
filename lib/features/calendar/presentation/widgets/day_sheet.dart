import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../../../core/utils/jalali_utils.dart';
import '../../../../core/utils/persian_digits.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../data/db/app_database.dart';
import '../../../../domain/work_entry_stats.dart';
import '../../../../shared/widgets/app_dialogs.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/work_entry_tile.dart';
import '../../../employers/state/employer_providers.dart';
import '../../state/calendar_providers.dart';
import 'work_entry_form_sheet.dart';

Future<void> showDaySheet(BuildContext context, DateTime day) {
  return showAppSheet<void>(
    context,
    heightFactor: 0.75,
    child: DaySheet(day: day),
  );
}

class DaySheet extends ConsumerWidget {
  const DaySheet({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iso = toIsoDate(day);
    final entries = ref.watch(dayEntriesProvider(iso)).value ?? const <WorkEntry>[];
    final employers = ref.watch(employersByIdProvider);
    final totals = summarizeEntries(entries);
    final theme = Theme.of(context);

    return AppSheet(
      title: formatJalaliFullLong(day),
      subtitle: entries.isEmpty ? null : _summary(totals),
      actions: [
        FilledButton.icon(
          onPressed: () => showWorkEntryFormSheet(context, initialDate: iso),
          icon: const Icon(Icons.add_rounded),
          label: const Text('افزودن روزکار'),
        ),
      ],
      child: entries.isEmpty
          ? const EmptyState(
              compact: true,
              title: 'این روز روزکاری ثبت نشده',
              message: 'با دکمه پایین، اولین روزکار این روز را اضافه کنید.',
            )
          : Column(
              children: [
                for (final entry in entries)
                  Dismissible(
                    key: ValueKey('entry-${entry.id}'),
                    direction: DismissDirection.horizontal,
                    confirmDismiss: (_) => _confirmDelete(context),
                    onDismissed: (_) => _delete(context, ref, entry),
                    background: _dismissBackground(theme, Alignment.centerRight),
                    secondaryBackground: _dismissBackground(
                      theme,
                      Alignment.centerLeft,
                    ),
                    child: WorkEntryTile(
                      entry: entry,
                      employer: employers[entry.employerId],
                      onTap: () => showWorkEntryFormSheet(context, entry: entry),
                      onLongPress: () => _showEntryActions(context, ref, entry),
                      trailing: IconButton(
                        tooltip: 'گزینه‌ها',
                        onPressed: () => _showEntryActions(context, ref, entry),
                        icon: const Icon(Icons.more_vert_rounded),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  String _summary(EntryTotals totals) {
    final parts = <String>[
      '${toPersianDigits(totals.entryCount)} روزکار',
      if (totals.hours.inMinutes > 0)
        formatDuration(totals.hours),
      if (totals.pendingCount > 0)
        '${toPersianDigits(totals.pendingCount)} دستمزد در انتظار',
    ];
    return parts.join(' · ');
  }

  Widget _dismissBackground(ThemeData theme, Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: theme.colorScheme.errorContainer,
      child: Icon(
        Icons.delete_outline_rounded,
        color: theme.colorScheme.onErrorContainer,
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) => confirmDialog(
    context,
    title: 'حذف روزکار؟',
    message: 'این روزکار حذف می‌شود. تا چند لحظه می‌توانید بازگردانید.',
    confirmLabel: 'حذف',
    destructive: true,
  );

  Future<void> _showEntryActions(
    BuildContext context,
    WidgetRef ref,
    WorkEntry entry,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('ویرایش'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showWorkEntryFormSheet(context, entry: entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('کپی به تاریخ دیگر'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showWorkEntryFormSheet(
                  context,
                  initialDate: toIsoDate(day),
                  initialEmployerId: entry.employerId,
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'حذف',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                if (await _confirmDelete(context) && context.mounted) {
                  await _delete(context, ref, entry);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, WorkEntry entry) async {
    await ref.read(workEntryDaoProvider).delete(entry.id);
    if (!context.mounted) return;
    showUndoSnackBar(
      context,
      message: 'روزکار حذف شد.',
      onUndo: () => ref.read(workEntryDaoProvider).restore(entry),
    );
  }
}
