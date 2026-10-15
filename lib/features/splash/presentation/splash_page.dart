import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_info.dart';
import '../../../shared/utils/motion.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key, this.errorMessage, this.onRetry});

  final String? errorMessage;
  final VoidCallback? onRetry;

  static const Color _top = Color(0xFF428E82);
  static const Color _bottom = Color(0xFF143F3A);

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotion(context);

    Widget logo = Image.asset(
      'assets/icon/splash_logo.png',
      width: 152,
      height: 152,
      filterQuality: FilterQuality.high,
    );
    Widget name = const Text(
      AppInfo.nameFa,
      style: TextStyle(
        fontFamily: 'Vazirmatn',
        fontWeight: FontWeight.w700,
        fontSize: 40,
        color: Colors.white,
        letterSpacing: 1,
      ),
    );
    Widget tagline = Text(
      AppInfo.taglineFa,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 13.5,
        height: 1.9,
        color: Colors.white.withValues(alpha: 0.82),
      ),
    );

    // The native splash already shows the same logo on the same gradient, so the
    // in-app splash does not fade the logo in again — that would blink.
    if (!reduced) {
      tagline = tagline
          .animate()
          .fadeIn(delay: 220.ms, duration: 450.ms)
          .slideY(begin: 0.18, end: 0);
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_top, _bottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  logo,
                  const SizedBox(height: 22),
                  name,
                  const SizedBox(height: 14),
                  tagline,
                  const Spacer(flex: 3),
                  if (errorMessage == null)
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    )
                  else
                    Column(
                      children: [
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: onRetry,
                          child: const Text('تلاش دوباره'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
