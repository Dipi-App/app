import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ColorChoice extends StatelessWidget {
  const ColorChoice({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final color in EmployerPalette.colors)
          _Swatch(
            color: color,
            selected: color == selected,
            onTap: () => onSelected(color),
            checkColor: theme.colorScheme.surface,
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
    required this.checkColor,
  });

  final int color;
  final bool selected;
  final VoidCallback onTap;
  final Color checkColor;

  @override
  Widget build(BuildContext context) {
    final base = Color(color);
    return Semantics(
      label: EmployerPalette.nameOf(color),
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: base,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? base : Colors.transparent,
              width: 3,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: base.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: selected
              ? Icon(Icons.check_rounded, size: 22, color: checkColor)
              : null,
        ),
      ),
    );
  }
}
