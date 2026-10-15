import 'package:flutter/material.dart';

import '../../domain/enums.dart';

class EmployerPalette {
  const EmployerPalette._();

  static const int defaultColor = 0xFF2E7D6F;

  static const List<int> colors = [
    0xFF2E7D6F,
    0xFF2F6FBF,
    0xFF8E44AD,
    0xFFC0562B,
    0xFFB8860B,
    0xFF3B7A3B,
    0xFFB03A5B,
    0xFF4A5BB5,
    0xFF0E7C86,
    0xFF8A6D3B,
    0xFF6D4C9F,
    0xFFB23A2F,
  ];

  static const List<String> _names = [
    'زمرد',
    'لاجورد',
    'نیلوفر',
    'گل‌نار',
    'زر',
    'سبز',
    'ارغوان',
    'بنفشه',
    'فیروزه',
    'خاکی',
    'شب‌بو',
    'شنگرف',
  ];

  static int colorAt(int index) => colors[index % colors.length];

  static String nameAt(int index) => _names[index % _names.length];

  static String nameOf(int color) {
    final index = colors.indexOf(color);
    return index == -1 ? 'رنگ دلخواه' : _names[index];
  }
}

class AppColors {
  const AppColors._();

  /// Brand seed: turquoise ink `teal800`. See [BrandColors] and
  /// `assets/branding/BRANDING.md`.
  static const int seed = 0xFF0D3B42;

  /// Brand accent: `gold700`.
  static const int accent = 0xFFD9962A;

  // Light-mode settlement colors, tuned for >= 4.5:1 on a light surface.
  static const int creditor = 0xFF1F6B5C;
  static const int debtor = 0xFFB3261E;
  static const int settled = 0xFF5F6368;
  static const int pending = 0xFF8A6A00;

  // Dark-mode variants, tuned for >= 4.5:1 on a dark surface.
  static const int creditorDark = 0xFF7FD9C4;
  static const int debtorDark = 0xFFFFB4AB;
  static const int settledDark = 0xFFB9C6C4;
  static const int pendingDark = 0xFFF5C453;

  /// Brightness-agnostic settlement color. Kept for code that already knows
  /// the mode; prefer [settlementColor] in widgets so dark mode stays readable.
  static Color forState(SettlementState state) => switch (state) {
    SettlementState.creditor => const Color(creditor),
    SettlementState.debtor => const Color(debtor),
    SettlementState.settled => const Color(settled),
  };

  /// Settlement color that adapts to the current theme brightness.
  static Color settlementColor(BuildContext context, SettlementState state) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (state) {
      SettlementState.creditor => Color(dark ? creditorDark : creditor),
      SettlementState.debtor => Color(dark ? debtorDark : debtor),
      SettlementState.settled => Color(dark ? settledDark : settled),
    };
  }

  /// Pending/"in wait" color that adapts to the current theme brightness.
  static Color pendingColor(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Color(dark ? pendingDark : pending);
  }
}
