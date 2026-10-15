import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/money.dart';
import '../../features/settings/state/settings_providers.dart';
import '../utils/motion.dart';

class MoneyText extends ConsumerWidget {
  const MoneyText({
    super.key,
    required this.amountRial,
    this.style,
    this.withUnit = true,
    this.signed = false,
    this.animate = false,
    this.textAlign,
    this.colorBySign = false,
  });

  final int amountRial;
  final TextStyle? style;
  final bool withUnit;
  final bool signed;
  final bool animate;
  final TextAlign? textAlign;
  final bool colorBySign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(
      settingsControllerProvider.select(
        (settings) => settings.value?.currencyUnit ?? CurrencyUnit.toman,
      ),
    );
    final theme = Theme.of(context);

    TextStyle? effectiveStyle = style;
    if (colorBySign) {
      final color = amountRial > 0
          ? const Color(0xFF2E7D6F)
          : amountRial < 0
          ? theme.colorScheme.error
          : theme.colorScheme.onSurfaceVariant;
      effectiveStyle = (style ?? theme.textTheme.bodyMedium)?.copyWith(
        color: color,
      );
    }

    final text = formatMoney(
      amountRial,
      unit,
      withUnit: withUnit,
      signed: signed,
    );

    if (!animate || reduceMotion(context)) {
      return Text(text, style: effectiveStyle, textAlign: textAlign);
    }

    return _AnimatedAmount(
      amountRial: amountRial,
      unitFactor: unit.rialFactor,
      builder: (value) => Text(
        formatMoney(value, unit, withUnit: withUnit, signed: signed),
        style: effectiveStyle,
        textAlign: textAlign,
      ),
    );
  }
}

class _AnimatedAmount extends StatelessWidget {
  const _AnimatedAmount({
    required this.amountRial,
    required this.unitFactor,
    required this.builder,
  });

  final int amountRial;
  final int unitFactor;
  final Widget Function(int value) builder;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: amountRial.toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final rounded = value.round();
        return builder((rounded ~/ unitFactor) * unitFactor);
      },
    );
  }
}
