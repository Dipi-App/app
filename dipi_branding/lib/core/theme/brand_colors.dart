import 'package:flutter/material.dart';

/// Dipi brand colors. Same values as the logo files.
abstract final class BrandColors {
  // Turquoise ink (Persian "firouzeh" family)
  static const Color teal900 = Color(0xFF08292F);
  static const Color teal800 = Color(0xFF0D3B42);
  static const Color teal600 = Color(0xFF14525C);

  // Gold
  static const Color gold300 = Color(0xFFF8D26A);
  static const Color gold500 = Color(0xFFF5C453);
  static const Color gold700 = Color(0xFFD9962A);

  /// Use as `ColorScheme.fromSeed(seedColor: BrandColors.seed)`.
  static const Color seed = teal800;

  /// Same as the app icon background.
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal600, teal900],
  );

  /// Same as the gold on the D mark.
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gold300, gold700],
  );
}
