import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../../../core/utils/jalali_utils.dart';
import '../../../../data/db/app_database.dart';
import '../../../../domain/enums.dart';
import '../../../../shared/widgets/app_dialogs.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/jalali_date_picker.dart';
import '../../../../shared/widgets/money_field.dart';
import '../../../employers/presentation/widgets/employer_form_sheet.dart';
import '../../../employers/state/employer_providers.dart';

Future<int?> showPaymentFormSheet(
  BuildContext context, {
  Payment? payment,
  int? initialEmployerId,
}) {
  return showAppSheet<int>(
    context,
    child: PaymentFormSheet(
      payment: payment,
      initialEmployerId: initialEmployerId,
    ),
  );
}

class PaymentFormSheet extends ConsumerStatefulWidget {
  const PaymentFormSheet({super.key, this.payment, this.initialEmployerId});

  final Payment? payment;
  final int? initialEmployerId;

  @override
  ConsumerState<PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends ConsumerState<PaymentFormSheet> {
  late final TextEditingController _note;
  int? _employerId;
  late DateTime _date;
  int? _amountRial;
  late PaymentType _type;
  String? _employerError;
  String? _amountError;
  bool _saving = false;

  bool get _isEditing => widget.payment != null;

  @override
  void initState() {
    super.initState();
    final payment = widget.payment;
    _note = TextEditingController(text: payment?.note ?? '');
    _employerId = payment?.employerId ?? widget.initialEmployerId;
    _date =
        tryParseIsoDate(payment?.date)?.toLocal() ?? dateOnly(DateTime.now());
    _amountRial = payment?.amount;
    _type = PaymentType.fromName(payment?.type);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showJalaliDatePicker(context, initialDate: _date);
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final employerError = _employerId == null ? 'کارفرما را انتخاب کنید.' : null;
    final amount = _amountRial;
    final amountError = (amount == null || amount <= 0)
        ? 'مبلغ پرداخت را وارد کنید.'
        : null;
    if (employerError != null || amountError != null) {
      setState(() {
        _employerError = employerError;
        _amountError = amountError;
      });
      return;
    }

    setState(() => _saving = true);
    final dao = ref.read(paymentDaoProvider);
    final note = _note.text.trim();
    final dateIso = toIsoDate(_date);

    try {
      if (_isEditing) {
        await dao.update(
          widget.payment!.id,
          PaymentsCompanion(
            employerId: Value(_employerId!),
            date: Value(dateIso),
            amount: Value(amount!),
            type: Value(_type.name),
            note: Value(note.isEmpty ? null : note),
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pop(widget.payment!.id);
        return;
      }

      final id = await dao.create(
        PaymentsCompanion.insert(
          employerId: _employerId!,
          date: dateIso,
          amount: amount!,
          createdAt: DateTime.now().toIso8601String(),
          type: Value(_type.name),
          note: Value(note.isEmpty ? null : note),
        ),
      );
      if (!mounted) return;
      showInfoSnackBar(context, 'پرداخت ثبت شد.');
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
          !active.any((employer) => employer.id == _employerId))
        employers[_employerId]!,
    ];

    return AppSheet(
      title: _isEditing ? 'ویرایش پرداخت' : 'پرداخت تازه',
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
                if (id != null && mounted) {
                  setState(() {
                    _employerId = id;
                    _employerError = null;
                  });
                }
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
              onChanged: (value) => setState(() {
                _employerId = value;
                _employerError = null;
              }),
            ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDate,
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
                  Icon(
                    Icons.event_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Text('تاریخ', style: theme.textTheme.bodyMedium),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      formatJalaliFullLong(_date),
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
          ),
          const SizedBox(height: 20),
          Text('نوع پرداخت', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in PaymentType.values)
                ChoiceChip(
                  label: Text(type.label),
                  selected: _type == type,
                  onSelected: (_) => setState(() => _type = type),
                ),
            ],
          ),
          const SizedBox(height: 20),
          MoneyField(
            valueRial: _amountRial,
            onChanged: (value) => setState(() {
              _amountRial = value;
              _amountError = null;
            }),
            label: 'مبلغ پرداخت',
            errorText: _amountError,
            helperText: switch (_type) {
              PaymentType.wage => 'مبلغی که بابت دستمزد به شما پرداخت شده است.',
              PaymentType.advance => 'مبلغی که پیش از کار یا میان کار گرفته‌اید.',
              PaymentType.expenseRefund =>
                'مبلغی که کارفرما بابت هزینه‌های شما پس داده است.',
            },
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
