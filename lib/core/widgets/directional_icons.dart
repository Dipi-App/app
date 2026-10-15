import 'package:flutter/material.dart';

/// Direction-aware chevrons, so no screen has to hardcode "left" or "right".
///
/// These Material icons carry `matchTextDirection: true`, which means Flutter
/// mirrors them automatically in RTL:
///   * [forward] points right in LTR and **left** in RTL.
///   * [back] points left in LTR and **right** in RTL.
///
/// Always use these (or another `matchTextDirection` icon) for arrows,
/// chevrons, month steppers and list affordances.
abstract final class DirectionalIcons {
  /// "Next / open / forward" affordance.
  static const IconData forward = Icons.chevron_right_rounded;

  /// "Previous / back" affordance.
  static const IconData back = Icons.chevron_left_rounded;
}
