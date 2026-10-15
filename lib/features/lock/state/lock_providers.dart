import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/utils/persian_digits.dart';
import '../../settings/state/settings_providers.dart';

/// True while the app should be showing the lock screen.
class AppLock extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsValueProvider).appLockEnabled;

  void lock() {
    final settings = ref.read(settingsValueProvider);
    if (settings.appLockEnabled && settings.hasPin) state = true;
  }

  void unlock() => state = false;
}

final appLockProvider = NotifierProvider<AppLock, bool>(AppLock.new);

/// Whether this device can do a biometric unlock.
final biometricSupportProvider = FutureProvider<bool>((ref) async {
  final auth = LocalAuthentication();
  try {
    if (!await auth.isDeviceSupported()) return false;
    final biometrics = await auth.getAvailableBiometrics();
    return biometrics.isNotEmpty;
  } catch (_) {
    return false;
  }
});

/// Asks the system for a fingerprint / face unlock. Never throws.
Future<bool> requestBiometricUnlock() async {
  final auth = LocalAuthentication();
  try {
    return await auth.authenticate(
      localizedReason: 'برای باز کردن دیپی هویت خود را تأیید کنید',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
  } catch (_) {
    return false;
  }
}

class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.length,
    required this.onCompleted,
    this.onChanged,
    this.errorText,
    this.autoSubmit = true,
    this.footer,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool autoSubmit;
  final Widget? footer;

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> {
  String _value = '';
  double _shakeToken = 0;

  String get value => _value;

  void clear() {
    setState(() => _value = '');
    widget.onChanged?.call('');
  }

  /// Shows the error state: clears the digits and shakes.
  void fail() {
    setState(() {
      _value = '';
      _shakeToken += 1;
    });
  }

  void _append(String digit) {
    if (_value.length >= widget.length) return;
    setState(() => _value += digit);
    widget.onChanged?.call(_value);
    if (_value.length == widget.length && widget.autoSubmit) {
      widget.onCompleted(_value);
    }
  }

  void _backspace() {
    if (_value.isEmpty) return;
    setState(() => _value = _value.substring(0, _value.length - 1));
    widget.onChanged?.call(_value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dots = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < widget.length; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 7),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index < _value.length
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
      ],
    );

    final keypad = Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final digit in row) _Key(digit: digit, onTap: _append),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            widget.footer ?? const SizedBox(width: 72),
            _Key(digit: '0', onTap: _append),
            _Key(icon: Icons.backspace_outlined, onTap: (_) => _backspace()),
          ],
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        dots.animate(target: _shakeToken).shakeX(amount: 5.0, duration: 300.ms),
        const SizedBox(height: 14),
        SizedBox(
          height: 22,
          child: widget.errorText == null
              ? null
              : Text(
                  widget.errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
        ),
        const SizedBox(height: 10),
        keypad,
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({this.digit, this.icon, required this.onTap});

  final String? digit;
  final IconData? icon;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 72,
      height: 60,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onTap(digit ?? ''),
          child: Center(
            child: digit != null
                ? Text(
                    toPersianDigits(digit!),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Icon(icon, size: 22),
          ),
        ),
      ),
    );
  }
}
