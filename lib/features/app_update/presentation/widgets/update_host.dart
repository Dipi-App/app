import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app_release.dart';
import '../../state/update_providers.dart';
import '../update_dialog.dart';

/// Headless helper mounted on the home screen. It runs the once-per-start check
/// (at most every 24 hours) and, when a newer release is found, offers the
/// update dialog once per app run.
class UpdateHost extends ConsumerStatefulWidget {
  const UpdateHost({super.key});

  @override
  ConsumerState<UpdateHost> createState() => _UpdateHostState();
}

class _UpdateHostState extends ConsumerState<UpdateHost> {
  bool _started = false;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (!mounted || _started) return;
    _started = true;
    final result = await ref
        .read(updateControllerProvider.notifier)
        .onAppStart();
    final release = result.release;
    if (!mounted || release == null) return;
    await _offer(release);
  }

  Future<void> _offer(AppRelease release) async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    try {
      await showUpdateDialog(context, release);
    } finally {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
