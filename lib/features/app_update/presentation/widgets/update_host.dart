import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/persian_digits.dart';
import '../../../../shared/widgets/app_dialogs.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../domain/update_machine.dart';
import '../../domain/update_phase.dart';
import '../../state/update_providers.dart';
import '../update_sheet.dart';

/// Headless helper mounted on the home screen. It:
///  * runs the once-per-start check,
///  * opens the "ready" modal by itself (but never on a form),
///  * shows the one-time "installed" message.
class UpdateHost extends ConsumerStatefulWidget {
  const UpdateHost({super.key});

  @override
  ConsumerState<UpdateHost> createState() => _UpdateHostState();
}

class _UpdateHostState extends ConsumerState<UpdateHost> {
  bool _started = false;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    appSheetDepth.addListener(_onSheetDepthChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _started) return;
      _started = true;
      ref.read(updateControllerProvider.notifier).onAppStart();
    });
  }

  @override
  void dispose() {
    appSheetDepth.removeListener(_onSheetDepthChanged);
    super.dispose();
  }

  void _onSheetDepthChanged() {
    if (appSheetDepth.value == 0) _maybeAutoOpen();
  }

  /// A form (or the keyboard) is open: do not pop the modal now.
  bool get _blocked {
    if (appSheetDepth.value > 0) return true;
    if (!mounted) return true;
    return MediaQuery.viewInsetsOf(context).bottom > 0;
  }

  void _maybeAutoOpen() {
    if (!mounted || _sheetOpen) return;
    final state = ref.read(updateControllerProvider);
    if (!UpdateMachine.shouldAutoOpen(state, blockedByForm: _blocked)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openSheet();
    });
  }

  Future<void> _openSheet() async {
    _sheetOpen = true;
    try {
      await showUpdateSheet(context);
    } finally {
      _sheetOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(updateControllerProvider, (previous, next) {
      if (next.phase == UpdatePhase.ready &&
          previous?.phase != UpdatePhase.ready) {
        _maybeAutoOpen();
      }
    });

    ref.listen(updateInstalledNoticeProvider, (previous, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showInfoSnackBar(context, 'نسخه جدید نصب شد (${toPersianDigits(next)})');
        ref.read(updateInstalledNoticeProvider.notifier).clear();
      });
    });

    return const SizedBox.shrink();
  }
}
