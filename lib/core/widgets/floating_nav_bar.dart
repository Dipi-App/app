import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/utils/motion.dart';
import '../theme/app_tokens.dart';

/// One tab of the [FloatingNavBar]. Every item always shows its icon *and* its
/// short Persian label, so a low-literacy user never has to guess.
@immutable
class FloatingNavItem {
  const FloatingNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.semanticLabel,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Spoken by screen readers; falls back to [label].
  final String? semanticLabel;
}

/// The big, unmistakable center action (for Dipi: "add workday").
@immutable
class FloatingNavPrimaryAction {
  const FloatingNavPrimaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? semanticLabel;
}

/// A hand-drawn floating bottom navigation bar.
///
/// * Floats above the screen edges (margin + safe area + gesture bar).
/// * The active icon scales up with a gentle bounce and the label turns bold.
/// * Respects the "reduce motion" accessibility setting (colours only).
/// * Is fully RTL aware (item order).
/// * Carries a semantic label per item for screen readers.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onSelected,
    this.primaryAction,
  }) : assert(
         items.length >= 2 && items.length <= 4,
         '2–4 tabs plus the primary action',
       );

  /// Index into [items].
  final int selectedIndex;
  final List<FloatingNavItem> items;
  final ValueChanged<int> onSelected;
  final FloatingNavPrimaryAction? primaryAction;

  int get _primarySlot => primaryAction == null ? -1 : items.length ~/ 2;

  int get _totalSlots => items.length + (primaryAction == null ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final bar = Padding(
      padding: EdgeInsets.fromLTRB(
        AppTokens.navMargin,
        AppTokens.space8,
        AppTokens.navMargin,
        AppTokens.navMargin + bottomInset,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTokens.radiusNav),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox(
          height: AppTokens.navHeight,
          child: Row(
            children: [
              for (var i = 0; i < _totalSlots; i++)
                Expanded(child: _slotAt(i)),
            ],
          ),
        ),
      ),
    );

    // Clamp the text scale a little so a huge system font can never overflow
    // the fixed-height bar (the labels stay readable, just not enormous).
    return MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: bar);
  }

  Widget _slotAt(int slotIndex) {
    final primarySlot = _primarySlot;
    if (slotIndex == primarySlot) {
      return _PrimarySlot(
        action: primaryAction!,
        height: AppTokens.navHeight,
      );
    }
    final tabIndex = slotIndex < primarySlot || primarySlot < 0
        ? slotIndex
        : slotIndex - 1;
    return _NavTab(
      item: items[tabIndex],
      selected: tabIndex == selectedIndex,
      onTap: () {
        if (tabIndex == selectedIndex) return;
        HapticFeedback.selectionClick();
        onSelected(tabIndex);
      },
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final FloatingNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduced = reduceMotion(context);
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: item.semanticLabel ?? item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        child: SizedBox(
          height: AppTokens.comfortableTapTarget,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected && !reduced ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 26,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                style: theme.textTheme.labelSmall!.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimarySlot extends StatelessWidget {
  const _PrimarySlot({required this.action, required this.height});

  final FloatingNavPrimaryAction action;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Gold accent stands out against the teal bar in both themes, with a dark
    // icon so the label/icon keep a >= 4.5:1 contrast.
    final background = scheme.secondary;
    final foreground = scheme.onSecondary;

    return Semantics(
      button: true,
      label: action.semanticLabel ?? action.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          action.onTap();
        },
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        child: SizedBox(
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(action.icon, size: 28, color: foreground),
              ),
              const SizedBox(height: 2),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
