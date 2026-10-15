import 'package:flutter/material.dart';

class EmployerDot extends StatelessWidget {
  const EmployerDot({
    super.key,
    required this.color,
    this.size = 12,
    this.icon,
  });

  final Color color;
  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return Container(
        width: size * 2,
        height: size * 2,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: size, color: color),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
