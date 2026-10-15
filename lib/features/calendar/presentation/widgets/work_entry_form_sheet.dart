import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import '../../../../core/providers/database_providers.dart';
import '../../../../core/utils/jalali_utils.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../data/db/app_database.dart';
import '../../../../domain/enums.dart';
import '../../../../shared/widgets/app_dialogs.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/jalali_date_picker.dart';
import '../../../../shared/widgets/money_field.dart';
import '../../../employers/presentation/widgets/employer_form_sheet.dart';
import '../../../employers/state/employer_providers.dart';
import '../../state/calendar_providers.dart';

Future<int?> showWorkEntryFormSheet(
  BuildContext context, {
  WorkEntry? entry,
  String? initialDate,
  int? initialEmployerId,
}) {
  return showAppSheet<int>(
    context,
    child: WorkEntryFormSheet(
      entry: entry,
      initialDate: initialDate,
      initialEmployerId: initialEmployerId,
    ),
  );
}

class WorkEntryFormSheet extends ConsumerStatefulWidget {
  const WorkEntryFormSheet({
    super.key,
    this.entry,
    this.initialDate,
    this.initialEmployerId,
  });

  final WorkEntry? entry;
  final String? initialDate;
  final int? initialEmployerId;

  @override
  ConsumerState<WorkEntryFormSheet> createState() => _WorkEntryFormSheetState();
}

class _WorkEntryFormSheetState extends ConsumerState<WorkEntryFormSheet> {
  late final TextEditingController _place;
  late final TextEditingController _job;
  late final TextEditingController _note;

  int? _employerId;
  late DateTime _date;
  TimeOfDay? _start;
  TimeOfDay? _end;
  late WageType _wageType;
  int? _wageRial;
  int? _outOfPocketRial;
  bool _wageTouched = false;
  String? _employerError;
  bool _saving = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _place = TextEditingController(text: entry?.place ?? '');
    _job = TextEditingController(text: entry?.job ?? '');
    _note = TextEditingController(text: entry?.note ?? '');
    _employerId = entry?.employerId ?? widget.initialEmployerId;
    _date = tryParseIsoDate(entry?.date ?? widget.initialDate) ?? dateOnly(DateTime.now());
    _start = decodeClock(entry?.startTime);
    _end = decodeClock(entry?.endTime);
    _wageType = WageType.fromName(entry?.wageType);
    _wageRial = entry?.wageAmount;
    _outOfPocketRial = entry != null && entry.outOfPocketAmount > 0
        ? entry.outOfPocketAmount
        : null;
    _wageTouched = entry != null;
  }

  @override
  void dispose() {
    _place.dispose();
    _job.dispose();
    _note.dispose();
    super.dispose();
  }

  void _onEmployerChanged(int? id) {
    setState(() {
      _employerId = id;
      _employerError = null;
    });
    if (id == null || _isEditing || _wageTouched) return;
    final employers = ref.read(employersByIdProvider);
    final employer = employers[id];
    if (employer == null) return;
    setState(() {
      _wageType = WageType.fromName(employer.defaultWageType);
      _wageRial = employer.defaultDailyWage;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showJalaliDatePicker(context, initialDate: _date);
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = (isStart ? _start : _end) ?? TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_employerId == null) {
      setState(() => _employerError = 'کارفرما را انتخاب کنید.');
      return;
    }
    setState(() => _saving = true);

    final dao = ref.read(workEntryDaoProvider);
    final place = _place.text.trim();
    final job = _job.text.trim();
    final note = _note.text.trim();
    final dateIso = toIsoDate(_date);
    final startIso = _start == null ? null : encodeClock(_start!);
    final endIso = _end == null ? null : encodeClock(_end!);

    try {
      if (_isEditing) {
        await dao.update(
          widget.entry!.id,
          WorkEntriesCompanion(
            employerId: Value(_employerId!),
            date: Value(dateIso),
            place: Value(place.isEmpty ? null : place),
            job: Value(job.isEmpty ? null : job),
            startTime: Value(startIso),
            endTime: Value(endIso),
            wageType: Value(_wageType.name),
            wageAmount: Value(_wageRial),
            outOfPocketAmount: Value(_outOfPocketRial ?? 0),
            note: Value(note.isEmpty ? null : note),
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pop(widget.entry!.id);
        return;
      }

      final id = await dao.create(
        WorkEntriesCompanion.insert(
          employerId: _employerId!,
          date: dateIso,
          createdAt: DateTime.now().toIso8601String(),
          place: Value(place.isEmpty ? null : place),
          job: Value(job.isEmpty ? null : job),
          startTime: Value(startIso),
          endTime: Value(endIso),
          wageType: Value(_wageType.name),
          wageAmount: Value(_wageRial),
          outOfPocketAmount: Value(_outOfPocketRial ?? 0),
          note: Value(note.isEmpty ? null : note),
        ),
      );
      if (!mounted) return;
      showInfoSnackBar(context, 'روزکار ثبت شد.');
      Navigator.of(context).pop(id);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final employers = ref.watch(employersByIdProvider);
    final active = ref.watch(activeEmployersProvider);
    final options = <Employer>[
      ...active,
      if (_employerId != null &&
          employers[_employerId] != null &&
          !active.any((e) => e.id == _employerId))
        employers[_employerId]!,
    ];

    final places = ref.watch(quickPlacesProvider).value ?? const <String>[];
    final jobs = ref.watch(quickJobsProvider).value ?? const <String>[];
    final duration = shiftDuration(
      _start == null ? null : encodeClock(_start!),
      _end == null ? null : encodeClock(_end!),
    );

    return AppSheet(
      title: _isEditing ? 'ویرایش روزکار' : 'روزکار تازه',
      subtitle: formatJalaliFullLong(_date),
      actions: [
        OutlinedButton(
          onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_isEditing ? 'ذخیره' : 'ثبت'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (options.isEmpty)
            _NoEmployersHint(
              onCreate: () async {
                final id = await showEmployerFormSheet(context);
                if (id != null && mounted) _onEmployerChanged(id);
              },
            )
          else
            DropdownButtonFormField<int>(
              initialValue: _employerId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'کارفرما',
                errorText: _employerError,
              ),
              items: [
                for (final employer in options)
                  DropdownMenuItem(
                    value: employer.id,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(employer.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            employer.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: _onEmployerChanged,
            ),
          const SizedBox(height: 16),
          _PickerTile(
            icon: Icons.event_outlined,
            label: 'تاریخ',
            value: formatJalaliFullLong(_date),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TimeField(
                  label: 'از ساعت',
                  time: _start,
                  onPick: () => _pickTime(isStart: true),
                  onClear: () => setState(() => _start = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeField(
                  label: 'تا ساعت',
                  time: _end,
                  onPick: () => _pickTime(isStart: false),
                  onClear: () => setState(() => _end = null),
                ),
              ),
            ],
          ),
          if (duration != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.timelapse_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'مدت: ${formatDuration(duration)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _place,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'محل کار (اختیاری)',
              hintText: 'مثلاً کارگاه شماره ۲',
            ),
          ),
          if (places.isNotEmpty) ...[
            const SizedBox(height: 8),
            _Suggestions(
              values: places,
              onSelected: (value) => setState(() => _place.text = value),
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _job,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'نوع کار (اختیاری)',
              hintText: 'مثلاً بنایی',
            ),
          ),
          if (jobs.isNotEmpty) ...[
            const SizedBox(height: 8),
            _Suggestions(
              values: jobs,
              onSelected: (value) => setState(() => _job.text = value),
            ),
          ],
          const SizedBox(height: 20),
          Text('دستمزد', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          SegmentedButton<WageType>(
            segments: [
              for (final type in WageType.values)
                ButtonSegment(value: type, label: Text(type.label)),
            ],
            selected: {_wageType},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => setState(() {
              _wageType = selection.first;
              _wageTouched = true;
            }),
          ),
          const SizedBox(height: 14),
          MoneyField(
            valueRial: _wageRial,
            onChanged: (value) => setState(() {
              _wageRial = value;
              _wageTouched = true;
            }),
            label: 'مبلغ دستمزد',
            helperText: _wageRial == null
                ? 'اگر مبلغ هنوز معلوم نیست، خالی بگذارید تا «در انتظار» بماند.'
                : null,
          ),
          const SizedBox(height: 20),
          MoneyField(
            valueRial: _outOfPocketRial,
            onChanged: (value) => setState(() => _outOfPocketRial = value),
            label: 'هزینه از جیب خودم (اختیاری)',
            helperText: 'پولی که شما برای کارفرما پرداخت کرده‌اید و باید حساب شود.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _note,
            maxLines: 3,
            minLines: 2,
            decoration: const InputDecoration(labelText: 'یادداشت (اختیاری)'),
          ),
        ],
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.values, required this.onSelected});

  final List<String> values;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values.take(8))
          ActionChip(
            label: Text(value),
            onPressed: () => onSelected(value),
          ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.45,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(label, style: theme.textTheme.bodyMedium),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.time,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final TimeOfDay? time;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.45,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time == null ? 'انتخاب' : formatClockText(encodeClock(time!)),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: time == null ? FontWeight.w400 : FontWeight.w600,
                      color: time == null
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (time != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
                visualDensity: VisualDensity.compact,
                tooltip: 'پاک کردن',
              ),
          ],
        ),
      ),
    );
  }
}

class _NoEmployersHint extends StatelessWidget {
  const _NoEmployersHint({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'اول یک کارفرما بسازید',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'هر روزکار به یک کارفرما وصل می‌شود. حساب هر کارفرما جدا نگه داشته می‌شود.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.7),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: onCreate,
            child: const Text('افزودن کارفرما'),
          ),
        ],
      ),
    );
  }
}
