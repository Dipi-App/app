import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/money.dart';
import '../../core/utils/persian_digits.dart';
import '../../features/settings/state/settings_providers.dart';

class MoneyField extends ConsumerStatefulWidget {
  const MoneyField({
    super.key,
    required this.valueRial,
    required this.onChanged,
    this.label = 'مبلغ',
    this.hint,
    this.autofocus = false,
    this.enabled = true,
    this.helperText,
    this.errorText,
  });

  final int? valueRial;
  final ValueChanged<int?> onChanged;
  final String label;
  final String? hint;
  final bool autofocus;
  final bool enabled;
  final String? helperText;
  final String? errorText;

  @override
  ConsumerState<MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends ConsumerState<MoneyField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: _displayText(widget.valueRial));
  }

  @override
  void didUpdateWidget(MoneyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueRial != widget.valueRial && !_focusNode.hasFocus) {
      _setText(_displayText(widget.valueRial));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  CurrencyUnit get _unit => ref.read(settingsValueProvider).currencyUnit;

  String _displayText(int? rialValue) {
    if (rialValue == null) return '';
    return toPersianDigits(groupDigits(_unit.fromRial(rialValue)));
  }

  void _setText(String text) {
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _handleChanged(String raw) {
    final digits = toEnglishDigits(raw).replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = digits.isEmpty ? null : int.tryParse(digits);
    _setText(parsed == null ? '' : toPersianDigits(groupDigits(parsed)));
    widget.onChanged(parsed == null ? null : _unit.toRial(parsed));
  }

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(
      settingsControllerProvider.select(
        (settings) => settings.value?.currencyUnit ?? CurrencyUnit.toman,
      ),
    );
    ref.listen(
      settingsControllerProvider.select(
        (settings) => settings.value?.currencyUnit ?? CurrencyUnit.toman,
      ),
      (previous, next) {
        if (previous != next) _setText(_displayText(widget.valueRial));
      },
    );

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      textInputAction: TextInputAction.next,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹٠-٩٬, ]')),
      ],
      onChanged: _handleChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: widget.errorText,
        suffixText: unit.label,
      ),
    );
  }
}
