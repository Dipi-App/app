import 'package:flutter/material.dart';

/// Shared layout tokens so every screen uses the same rhythm, radii and
/// touch sizes. Keeping them in one place makes the low-literacy "big and
/// roomy" rule easy to keep.
abstract final class AppTokens {
  // Spacing scale (multiples of 4).
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  // Radii.
  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 20;
  static const double radiusCard = 20;
  static const double radiusSheet = 28;
  static const double radiusNav = 26;

  // Touch targets.
  static const double minTapTarget = 48;
  static const double comfortableTapTarget = 56;

  // The floating navigation bar geometry.
  //
  // Outer margin from the screen edges / bottom (12–16) plus the system safe
  // area; inner padding inside the bar (8–12) around the item content.
  static const double navMargin = 14;
  static const double navInnerPadding = 8;

  /// Total bar height: a 56-item plus the inner padding on both sides.
  static const double navHeight =
      comfortableTapTarget + 2 * navInnerPadding;

  /// Bottom padding screens must add to their scroll area so content never
  /// hides behind the floating navigation bar or the system gesture bar.
  static double navClearance(BuildContext context) =>
      navHeight +
      navMargin +
      MediaQuery.paddingOf(context).bottom +
      space16;
}
