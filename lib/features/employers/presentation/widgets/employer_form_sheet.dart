import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/enums.dart';
import '../../../../shared/widgets/app_dialogs.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/money_field.dart';
import 'package:drift/drift.dart' show Value;

import '../../../../data/db/app_database.dart';
import 'color_choice.dart';

Future<int?> showEmployerFormSheet(
  BuildContext context, {
  Employer? employer,
}) {
  return showAppSheet<int>(
    context,
    child: EmployerFormSheet(employer: employer),
  );
}

class EmployerFormSheet extends ConsumerStatefulWidget {
  const EmployerFormSheet({super.key, this.employer});

  final Employer? employer;

  @override
  ConsumerState<EmployerFormSheet> createState() => _EmployerFormSheetState();
}

class _EmployerFormSheetState extends ConsumerState<EmployerFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _note;

  late int _color;
  late WageType _wageType;
  int? _dailyWageRial;
  String? _nameError;

  bool get _isEditing => widget.employer != null;

  @override
  void initState() {
    super.initState();
    final employer = widget.employer;
    _name = TextEditingController(text: employer?.name ?? '');
    _phone = TextEditingController(text: employer?.phone ?? '');
    _note = TextEditingController(text: employer?.note ?? '');
    _color = employer?.color ?? EmployerPalette.defaultColor;
    _wageType = WageType.fromName(employer?.defaultWageType);
    _dailyWageRial = employer?.defaultDailyWage;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'نام کارفرما را وارد کنید.');
      return;
    }

    final dao = ref.read(employerDaoProvider);
    final phone = _phone.text.trim();
    final note = _note.text.trim();

    if (_isEditing) {
      await dao.patch(
        widget.employer!.id,
        EmployersCompanion(
          name: Value(name),
          color: Value(_color),
          phone: Value(phone.isEmpty ? null : phone),
          note: Value(note.isEmpty ? null : note),
          defaultWageType: Value(_wageType.name),
          defaultDailyWage: Value(_dailyWageRial),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(widget.employer!.id);
      return;
    }

    final id = await dao.create(
      name: name,
      color: _color,
      phone: phone.isEmpty ? null : phone,
      note: note.isEmpty ? null : note,
      defaultWageType: _wageType.name,
      defaultDailyWage: _dailyWageRial,
    );
    if (!mounted) return;
    showInfoSnackBar(context, 'کارفرما «$name» اضافه شد.');
    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: _isEditing ? 'ویرایش کارفرما' : 'کارفرمای تازه',
      subtitle: _isEditing ? null : 'دستمزد پیش‌فرض اختیاری است و در فرم روزکار پیشنهاد می‌شود.',
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_isEditing ? 'ذخیره' : 'افزودن'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            autofocus: !_isEditing,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            decoration: InputDecoration(
              labelText: 'نام کارفرما',
              hintText: 'مثلاً کارگاه آفتاب',
              errorText: _nameError,
            ),
          ),
          const SizedBox(height: 20),
          Text('رنگ', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          ColorChoice(
            selected: _color,
            onSelected: (color) => setState(() => _color = color),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              labelText: 'شماره تماس (اختیاری)',
            ),
          ),
          const SizedBox(height: 20),
          Text('دستمزد پیش‌فرض', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          SegmentedButton<WageType>(
            segments: [
              for (final type in WageType.values)
                ButtonSegment(value: type, label: Text(type.label)),
            ],
            selected: {_wageType},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => _wageType = selection.first),
          ),
          const SizedBox(height: 14),
          MoneyField(
            valueRial: _dailyWageRial,
            onChanged: (value) => setState(() => _dailyWageRial = value),
            label: 'دستمزد روزانه (اختیاری)',
            helperText: _wageType == WageType.variable
                ? 'برای دستمزد متغیر، به جای این مقدار هر روز را جدا وارد می‌کنید.'
                : null,
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
