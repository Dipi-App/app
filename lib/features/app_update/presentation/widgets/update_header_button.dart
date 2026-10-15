import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/brand_colors.dart';
import '../../../../shared/utils/motion.dart';
import '../../state/update_providers.dart';
import '../update_dialog.dart';

/// The new-version icon in the shared header (far left in RTL).
///
/// Hidden until a check finds a newer release; then a download arrow opens the
/// update dialog. Always at least 48x48.
class UpdateHeaderButton extends ConsumerWidget {
  const UpdateHeaderButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final release = ref.watch(
      updateControllerProvider.select((state) => state.available),
    );
    if (release == null) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: IconButton(
        key: const ValueKey('update-available'),
        tooltip: 'نسخه جدید هست',
        onPressed: () => showUpdateDialog(context, release),
        icon: Icon(
          Icons.download_rounded,
          color: BrandColors.gold500,
        ),
      ),
    );
  }
}
