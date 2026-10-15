import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../utils/motion.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.action,
    this.icon,
    this.assetPath = 'assets/lottie/empty.json',
    this.compact = false,
  });

  final String title;
  final String? message;
  final Widget? action;
  final IconData? icon;
  final String assetPath;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final header = icon == null
        ? SizedBox(
            height: compact ? 96 : 130,
            child: Lottie.asset(
              assetPath,
              repeat: !reduceMotion(context),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.inbox_outlined,
                size: compact ? 44 : 56,
                color: theme.colorScheme.outline,
              ),
            ),
          )
        : Icon(icon, size: compact ? 44 : 56, color: theme.colorScheme.outline);

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!reduceMotion(context))
          header.animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0)
        else
          header,
        SizedBox(height: compact ? 12 : 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.7,
            ),
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 20),
          action!,
        ],
      ],
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: body,
        ),
      ),
    );
  }
}
