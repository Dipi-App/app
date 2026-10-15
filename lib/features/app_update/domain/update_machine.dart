import 'app_release.dart';
import 'release_asset.dart';
import 'update_phase.dart';
import 'update_state.dart';

/// The APK + checksum pair chosen for this device.
class UpdateTarget {
  const UpdateTarget({required this.apk, required this.checksum});

  final ReleaseAsset apk;
  final ReleaseAsset? checksum;
}

/// The pure heart of the update flow: every phase change goes through here so
/// it can be unit-tested without any network, files or widgets.
abstract final class UpdateMachine {
  /// After a successful check. `onWifi` decides whether the download may start
  /// by itself; otherwise the state waits in [UpdatePhase.available].
  static UpdateState afterCheck(
    UpdateState current, {
    required AppRelease? release,
    required bool onWifi,
    required bool wifiOnly,
  }) {
    if (release == null) {
      return current.copyWith(phase: UpdatePhase.hidden, clearError: true);
    }
    final startNow = onWifi || !wifiOnly;
    return UpdateState(
      phase: startNow ? UpdatePhase.downloading : UpdatePhase.available,
      release: release,
      dismissedThisSession: current.dismissedThisSession,
    );
  }

  /// Attaches the chosen APK/size and any partial bytes already on disk.
  static UpdateState withTarget(
    UpdateState current, {
    required UpdateTarget target,
    required int existingBytes,
  }) {
    return current.copyWith(
      apk: target.apk,
      checksum: target.checksum,
      totalBytes: target.apk.sizeInBytes,
      receivedBytes: existingBytes,
      clearError: true,
    );
  }

  static UpdateState onProgress(UpdateState current, int received, int total) {
    return current.copyWith(
      phase: UpdatePhase.downloading,
      receivedBytes: received,
      totalBytes: total > 0 ? total : current.totalBytes,
    );
  }

  static UpdateState onDownloaded(UpdateState current) {
    return current.copyWith(
      phase: UpdatePhase.ready,
      receivedBytes: current.totalBytes,
    );
  }

  static UpdateState onError(UpdateState current, String message) {
    return current.copyWith(phase: UpdatePhase.error, errorMessage: message);
  }

  /// The user cancelled: keep the release so they can start again.
  static UpdateState onCancelled(UpdateState current) {
    return current.copyWith(
      phase: UpdatePhase.available,
      receivedBytes: 0,
      clearError: true,
    );
  }

  static UpdateState onStartAgain(UpdateState current) {
    return current.copyWith(phase: UpdatePhase.downloading, clearError: true);
  }

  static UpdateState onDismissed(UpdateState current) {
    return current.copyWith(dismissedThisSession: true);
  }

  /// Should the "ready" modal open on its own right now?
  static bool shouldAutoOpen(UpdateState state, {required bool blockedByForm}) {
    return state.phase == UpdatePhase.ready &&
        !state.dismissedThisSession &&
        !blockedByForm;
  }
}
