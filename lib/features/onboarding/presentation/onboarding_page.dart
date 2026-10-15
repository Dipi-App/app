import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../shared/utils/motion.dart';
import '../../settings/state/settings_providers.dart';

class _Slide {
  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, this.onFinish});

  /// Called when the user finishes or skips. Defaults to popping the route.
  final VoidCallback? onFinish;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      icon: Icons.menu_book_rounded,
      title: 'به دیپی خوش آمدی',
      body: 'دیپی مثل یک دفتر یادداشت ساده است؛ می‌نویسی برای کی کار کرده‌ای '
          'و چقدر پول گرفته‌ای.',
    ),
    _Slide(
      icon: Icons.event_available_rounded,
      title: 'هر روز کار، یک روزکار',
      body: 'دکمه بزرگ «روزکار» را بزن، کارفرما را انتخاب کن و ثبت کن. همین!',
    ),
    _Slide(
      icon: Icons.account_balance_wallet_rounded,
      title: 'حسابت را بدان',
      body: 'سبز یعنی کارفرما به تو بدهکار است و سرخ یعنی تو به او. همه چیز با '
          'عدد و رنگ روشن است.',
    ),
    _Slide(
      icon: Icons.lock_outline_rounded,
      title: 'اطلاعات تو پیش خودت می‌ماند',
      body: 'دیپی بدون اینترنت کار می‌کند. هیچ چیزی از گوشی‌ات بیرون نمی‌رود.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    // Make sure the settings notifier is built before writing to it.
    await ref.read(settingsControllerProvider.future);
    await ref.read(settingsControllerProvider.notifier).setOnboardingSeen(true);
    if (!mounted) return;
    if (widget.onFinish != null) {
      widget.onFinish!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _next() {
    if (_page >= _slides.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: reduceMotion(context)
            ? Duration.zero
            : const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: _finish,
                child: const Text('رد کردن'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slide.icon,
                            size: 64,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space32),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space16),
                        Text(
                          slide.body,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? scheme.primary
                          : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space24,
                AppTokens.space24,
                AppTokens.space24,
                AppTokens.space16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTokens.space4,
                    ),
                    child: Text(
                      _page >= _slides.length - 1 ? 'شروع کن' : 'بعدی',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
