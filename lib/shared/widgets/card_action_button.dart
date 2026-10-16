import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// A small icon action for card headers (edit / delete).
///
/// Paints at 36dp but keeps a 48dp tap target; the tooltip doubles as the
/// semantic label in Persian.
class CardActionButton extends StatelessWidget {
  const CardActionButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color? color;

  static const double _visualSize = 36;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: semanticLabel,
      icon: Icon(icon, size: 20),
      color: color,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: _visualSize,
        height: _visualSize,
      ),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
      ),
    );
  }
}
