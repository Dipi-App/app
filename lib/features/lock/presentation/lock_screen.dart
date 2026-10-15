import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/utils/persian_digits.dart';
import '../../../core/utils/pin_hash.dart';
import '../../../shared/utils/motion.dart';
import '../../settings/state/settings_providers.dart';
import '../state/lock_providers.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final GlobalKey<PinPadState> _padKey = GlobalKey<PinPadState>();
  String? _error;
  int _attempts = 0;

  int get _pinLength => ref.read(settingsValueProvider).appLockPinLength ?? 4;

  @override
  void initState() {
    super.initState();
    // Offer the fingerprint as soon as the screen appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = ref.read(settingsValueProvider);
      final supported = ref.read(biometricSupportProvider).value ?? false;
      if (settings.biometricEnabled && supported) _tryBiometric();
    });
  }

  void _submit(String pin) {
    final settings = ref.read(settingsValueProvider);
    if (verifyPin(
      pin,
      hash: settings.appLockPinHash,
      salt: settings.appLockSalt,
    )) {
      ref.read(appLockProvider.notifier).unlock();
      return;
    }
    setState(() {
      _attempts++;
      _error = _attempts >= 3
          ? 'رمز نادرست است. اگر رمز را فراموش کرده‌اید، از پشتیبان '
                'بازگردانی کنید.'
          : 'رمز نادرست است.';
    });
    _padKey.currentState?.fail();
  }

  Future<void> _tryBiometric() async {
    final ok = await requestBiometricUnlock();
    if (!mounted) return;
    if (ok) {
      ref.read(appLockProvider.notifier).unlock();
    } else {
      setState(() => _error = 'اثر انگشت تأیید نشد.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsValueProvider);
    final biometricSupported = ref.watch(biometricSupportProvider).value ?? false;
    final useBiometric = settings.biometricEnabled && biometricSupported;
    final reduced = reduceMotion(context);

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        Icon(
          Icons.lock_outline_rounded,
          size: 44,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 14),
        Text(
          AppInfo.nameFa,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'رمز ${toPersianDigits(_pinLength)} رقمی را وارد کنید',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 26),
        PinPad(
          key: _padKey,
          length: _pinLength,
          errorText: _error,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onCompleted: _submit,
          footer: useBiometric
              ? SizedBox(
                  width: 72,
                  height: 60,
                  child: Material(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _tryBiometric,
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 26,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                )
              : null,
        ),
        const Spacer(flex: 3),
      ],
    );

    if (!reduced) {
      content = content
          .animate()
          .fadeIn(duration: 260.ms)
          .slideY(begin: 0.03, end: 0, duration: 300.ms);
    }

    return Scaffold(body: SafeArea(child: content));
  }
}
