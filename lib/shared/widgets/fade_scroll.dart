import 'package:flutter/material.dart';

/// Wraps a horizontally scrollable row (a filter chip row) with a soft fade at
/// both edges, hinting that there is more to scroll.
class FadeScroll extends StatelessWidget {
  const FadeScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0x00000000),
          Color(0xFF000000),
          Color(0xFF000000),
          Color(0x00000000),
        ],
        stops: [0.0, 0.04, 0.96, 1.0],
      ).createShader(rect),
      child: child,
    );
  }
}
