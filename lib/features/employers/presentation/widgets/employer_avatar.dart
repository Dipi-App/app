import 'package:flutter/material.dart';

class EmployerAvatar extends StatelessWidget {
  const EmployerAvatar({
    super.key,
    required this.name,
    required this.color,
    this.size = 44,
  });

  final String name;
  final int color;
  final double size;

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '؟';
    return String.fromCharCode(trimmed.runes.first);
  }

  @override
  Widget build(BuildContext context) {
    final base = Color(color);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: base.withValues(alpha: 0.45), width: 1.4),
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
          color: base,
        ),
      ),
    );
  }
}
