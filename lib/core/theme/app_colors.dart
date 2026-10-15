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

  static const int seed = 0xFF2E7D6F;
  static const int accent = 0xFFC0562B;

  static const int creditor = 0xFF2E7D6F;
  static const int debtor = 0xFFC0392B;
  static const int settled = 0xFF7A7A7A;
  static const int pending = 0xFFB8860B;

  static Color forState(SettlementState state) => switch (state) {
    SettlementState.creditor => const Color(creditor),
    SettlementState.debtor => const Color(debtor),
    SettlementState.settled => const Color(settled),
  };
}
