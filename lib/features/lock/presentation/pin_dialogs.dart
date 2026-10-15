import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/persian_digits.dart';
import '../../../core/utils/pin_hash.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../settings/state/settings_providers.dart';
import '../state/lock_providers.dart';

/// Asks for a brand new PIN twice (enter, then confirm) and returns it, or null
/// when the user cancels.
Future<String?> askNewPin(
  BuildContext context, {
  String title = 'تعیین رمز',
  String? subtitle,
}) {
  return showAppSheet<String>(
    context,
    heightFactor: 0.92,
    child: _NewPinSheet(title: title, subtitle: subtitle),
  );
}

/// Asks for the current PIN and verifies it against the stored hash.
Future<bool> confirmCurrentPin(
  BuildContext context,
  WidgetRef ref, {
  String title = 'رمز فعلی را وارد کنید',
}) async {
  final result = await showAppSheet<bool>(
    context,
    heightFactor: 0.92,
    child: _VerifyPinSheet(title: title),
  );
  return result ?? false;
}

class _NewPinSheet extends StatefulWidget {
  const _NewPinSheet({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  State<_NewPinSheet> createState() => _NewPinSheetState();
}

class _NewPinSheetState extends State<_NewPinSheet> {
  final GlobalKey<PinPadState> _padKey = GlobalKey<PinPadState>();
  String? _first;
  String? _error;
  int _enteredLength = 0;

  bool get _confirming => _first != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSheet(
      title: _confirming ? 'تکرار رمز' : widget.title,
      subtitle: _confirming
          ? 'همان رمز را یک بار دیگر وارد کنید.'
          : widget.subtitle ??
                'رمز ۴ تا ۸ رقمی. این رمز فقط روی همین گوشی ذخیره می‌شود و '
                    'به هیچ سروری نمی‌رود.',
      actions: [
        if (!_confirming)
          FilledButton(
            onPressed: !_canSubmit
                ? null
                : () {
                    final pin = _padKey.currentState!.value;
                    setState(() {
                      _first = pin;
                      _enteredLength = 0;
                    });
                    // The same PinPad instance is reused for the confirm step,
                    // so clear it instead of carrying the entry over.
                    _padKey.currentState?.clear();
                  },
            child: const Text('ادامه'),
          )
        else
          // Keeps the keypad in the same place on both steps.
          const SizedBox(height: 50),
      ],
      child: Column(
        children: [
          const SizedBox(height: 8),
          PinPad(
            key: _padKey,
            length: _confirming ? _first!.length : 8,
            autoSubmit: _confirming,
            errorText: _error,
            onChanged: (value) => setState(() {
              _enteredLength = value.length;
              if (_error != null) _error = null;
            }),
            onCompleted: _submit,
          ),
          // The hint stays in both steps so the keypad does not jump when the
          // sheet switches from "enter" to "confirm".
          const SizedBox(height: 12),
          Text(
            _confirming ? 'برای تأیید، همان رمز را دوباره وارد کنید.' : 'حداقل ۴ رقم',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  bool get _canSubmit => _confirming || _enteredLength >= 4;

  void _submit(String value) {
    if (!_confirming) {
      setState(() => _first = value);
      return;
    }
    if (value == _first) {
      Navigator.of(context).pop(_first);
      return;
    }
    _padKey.currentState?.fail();
    setState(() {
      _error = 'رمزها یکسان نیستند. دوباره تلاش کنید.';
      _first = null;
      _enteredLength = 0;
    });
  }
}

class _VerifyPinSheet extends ConsumerStatefulWidget {
  const _VerifyPinSheet({required this.title});

  final String title;

  @override
  ConsumerState<_VerifyPinSheet> createState() => _VerifyPinSheetState();
}

class _VerifyPinSheetState extends ConsumerState<_VerifyPinSheet> {
  final GlobalKey<PinPadState> _padKey = GlobalKey<PinPadState>();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsValueProvider);
    final length = settings.appLockPinLength ?? 4;

    return AppSheet(
      title: widget.title,
      subtitle: 'برای ادامه رمز ${toPersianDigits(length)} رقمی خود را وارد کنید.',
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: PinPad(
          key: _padKey,
          length: length,
          errorText: _error,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onCompleted: (value) {
            if (verifyPin(
              value,
              hash: settings.appLockPinHash,
              salt: settings.appLockSalt,
            )) {
              Navigator.of(context).pop(true);
              return;
            }
            setState(() => _error = 'رمز نادرست است.');
            _padKey.currentState?.fail();
          },
        ),
      ),
    );
  }
}
