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
/// * The active pill slides smoothly between items instead of jumping.
/// * The active icon scales up with a gentle bounce and the label turns bold.
/// * Respects the "reduce motion" accessibility setting (colors only).
/// * Is fully RTL aware (item order and slide direction).
/// * Carries a semantic label per item for screen readers.
class FloatingNavBar extends StatefulWidget {
  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onSelected,
    this.primaryAction,
  }) : assert(items.length >= 2 && items.length <= 4, '2–4 tabs plus the primary action');

  /// Index into [items].
  final int selectedIndex;
  final List<FloatingNavItem> items;
  final ValueChanged<int> onSelected;
  final FloatingNavPrimaryAction? primaryAction;

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 300);

  late final AnimationController _controller;
  late Animation<double> _slotAnimation;
  double _slot = 0;

  int get _primarySlot =>
      widget.primaryAction == null ? -1 : widget.items.length ~/ 2;

  int get _totalSlots => widget.items.length + (widget.primaryAction == null ? 0 : 1);

  int _slotForTab(int tabIndex) {
    final primary = _primarySlot;
    if (primary < 0 || tabIndex < primary) return tabIndex;
    return tabIndex + 1;
  }

  @override
  void initState() {
    super.initState();
    _slot = _slotForTab(widget.selectedIndex).toDouble();
    _controller = AnimationController(vsync: this, duration: _duration);
    _slotAnimation = Tween<double>(begin: _slot, end: _slot).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _slot = _slotAnimation.value;
    });
  }

  @override
  void didUpdateWidget(FloatingNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.primaryAction != widget.primaryAction) {
      final target = _slotForTab(widget.selectedIndex).toDouble();
      // Retarget from wherever the pill currently is so fast taps stay smooth.
      _slotAnimation = Tween<double>(begin: _slotAnimation.value, end: target)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      if (reduceMotion(context)) {
        _controller.value = 1;
        _slot = target;
      } else {
        _controller
          ..reset()
          ..forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTab(int index) {
    if (index == widget.selectedIndex) return;
    HapticFeedback.selectionClick();
    widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final slotWidth = width / _totalSlots;
              final pillWidth = slotWidth - AppTokens.space8;
              final rtl = Directionality.of(context) == TextDirection.rtl;

              double leftForSlot(double slot) {
                final fromLeft = rtl
                    ? width - (slot + 1) * slotWidth
                    : slot * slotWidth;
                return fromLeft + AppTokens.space4;
              }

              return Stack(
                children: [
                  // Sliding pill highlight behind the active tab.
                  AnimatedBuilder(
                    animation: _slotAnimation,
                    builder: (context, _) {
                      return Positioned(
                        left: leftForSlot(_slotAnimation.value),
                        top: AppTokens.space4,
                        bottom: AppTokens.space4,
                        width: pillWidth,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusLarge,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < _totalSlots; i++)
                        Expanded(child: _slotAt(i, slotWidth)),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _slotAt(int slotIndex, double slotWidth) {
    final primarySlot = _primarySlot;
    if (slotIndex == primarySlot) {
      return _PrimarySlot(
        action: widget.primaryAction!,
        height: AppTokens.navHeight,
      );
    }
    final tabIndex = slotIndex < primarySlot || primarySlot < 0
        ? slotIndex
        : slotIndex - 1;
    return _NavTab(
      item: widget.items[tabIndex],
      selected: tabIndex == widget.selectedIndex,
      onTap: () => _handleTab(tabIndex),
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
