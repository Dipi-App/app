import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/brand_colors.dart';
import '../../../../shared/utils/motion.dart';
import '../../domain/update_phase.dart';
import '../../state/update_providers.dart';
import '../update_sheet.dart';

/// The new-version icon in the shared header (far left in RTL).
///
/// States: hidden, available (download arrow), downloading (ring + percent),
/// ready (gold check, calm pulse) and error (warning). Always at least 48x48.
class UpdateHeaderButton extends ConsumerWidget {
  const UpdateHeaderButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);
    if (state.phase == UpdatePhase.hidden) return const SizedBox.shrink();

    final child = switch (state.phase) {
      UpdatePhase.hidden => const SizedBox.shrink(),
      UpdatePhase.available => _icon(
        icon: Icons.download_rounded,
        tooltip: 'نسخه جدید آماده دانلود',
        onTap: () => showUpdateSheet(context),
      ),
      UpdatePhase.downloading => _icon(
        icon: Icons.downloading_rounded,
        tooltip: 'در حال دانلود نسخه جدید',
        onTap: () => showUpdateSheet(context),
        ring: state.progress,
      ),
      UpdatePhase.ready => _Pulse(
        child: _icon(
          icon: Icons.check_circle_rounded,
          color: BrandColors.gold500,
          tooltip: 'نسخه جدید آماده نصب است',
          onTap: () => showUpdateSheet(context),
        ),
      ),
      UpdatePhase.error => _icon(
        icon: Icons.warning_amber_rounded,
        color: Theme.of(context).colorScheme.error,
        tooltip: 'دانلود نسخه جدید ناموفق بود. برای تلاش دوباره بزن',
        onTap: () {
          ref.read(updateControllerProvider.notifier).retry();
          showUpdateSheet(context);
        },
      ),
    };

    return AnimatedSwitcher(
      duration: reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: KeyedSubtree(key: ValueKey(state.phase), child: child),
    );
  }

  Widget _icon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
    double? ring,
  }) {
    Widget content = Icon(icon, color: color);
    if (ring != null) {
      content = Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              value: ring <= 0 ? null : ring,
              strokeWidth: 3,
            ),
          ),
          Icon(icon, size: 18, color: color),
        ],
      );
    }
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: content,
    );
  }
}

/// A gentle, calm pulse for the "ready" state. Still under reduce-motion.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) {
      _controller.stop();
      return widget.child;
    }
    if (!_controller.isAnimating) _controller.repeat(reverse: true);
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1).animate(curved),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.05).animate(curved),
        child: widget.child,
      ),
    );
  }
}
