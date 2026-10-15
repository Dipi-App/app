import 'package:flutter/material.dart';

import '../../core/theme/brand_colors.dart';

/// The Dipi mark: a "D" with a cuneiform wedge cut out of it.
///
/// Uses the same path as `assets/branding/dipi_mark.svg`.
/// If [color] is null, the gold gradient is used.
class DipiMark extends StatelessWidget {
  const DipiMark({super.key, this.size = 96, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * _h / _w),
      painter: _DipiMarkPainter(color),
    );
  }
}

/// Mark with an optional name below it. Fades and scales in once.
class DipiLogo extends StatelessWidget {
  const DipiLogo({
    super.key,
    this.size = 120,
    this.color,
    this.showName = false,
    this.animate = true,
    this.nameStyle,
  });

  final double size;
  final Color? color;
  final bool showName;
  final bool animate;
  final TextStyle? nameStyle;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DipiMark(size: size, color: color),
        if (showName) ...[
          SizedBox(height: size * 0.16),
          Text(
            'دیپی',
            style: nameStyle ??
                Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color ?? BrandColors.gold500,
                      fontWeight: FontWeight.w800,
                    ),
          ),
        ],
      ],
    );

    if (!animate || MediaQuery.of(context).disableAnimations) return content;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
      ),
      child: content,
    );
  }
}

// ---- drawing ----

// Mark box in the 1024 design space: x 301..723, y 300..724.
const double _x0 = 301, _y0 = 300, _w = 422, _h = 424;

class _DipiMarkPainter extends CustomPainter {
  const _DipiMarkPainter(this.color);

  final Color? color;

  static Path _buildPath() {
    final d = Path()
      ..moveTo(337, 300)
      ..lineTo(511, 300)
      ..arcToPoint(const Offset(511, 724),
          radius: const Radius.circular(212), clockwise: true)
      ..lineTo(337, 724)
      ..quadraticBezierTo(301, 724, 301, 688)
      ..lineTo(301, 336)
      ..quadraticBezierTo(301, 300, 337, 300)
      ..close();

    // The wedge. Even-odd fill makes it a hole.
    final wedge = Path()
      ..moveTo(390.4, 436.0)
      ..lineTo(523.9, 382.1)
      ..lineTo(497.9, 463.2)
      ..lineTo(542.8, 621.0)
      ..lineTo(465.5, 476.3)
      ..close();

    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(d, Offset.zero)
      ..addPath(wedge, Offset.zero);
  }

  static final Path _path = _buildPath();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _w;
    canvas.save();
    canvas.scale(scale);
    canvas.translate(-_x0, -_y0);

    final paint = Paint()..isAntiAlias = true;
    if (color != null) {
      paint.color = color!;
    } else {
      paint.shader = BrandColors.gold.createShader(
        Rect.fromLTWH(_x0, _y0, _w, _h),
      );
    }
    canvas.drawPath(_path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DipiMarkPainter old) => old.color != color;
}
