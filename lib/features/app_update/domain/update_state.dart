import 'app_release.dart';
import 'release_asset.dart';
import 'update_phase.dart';

/// Everything the header icon and the modal need to render.
class UpdateState {
  const UpdateState({
    this.phase = UpdatePhase.hidden,
    this.release,
    this.apk,
    this.checksum,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
    this.dismissedThisSession = false,
  });

  final UpdatePhase phase;
  final AppRelease? release;
  final ReleaseAsset? apk;
  final ReleaseAsset? checksum;
  final int receivedBytes;
  final int totalBytes;
  final String? errorMessage;

  /// True once the user tapped "بعداً" for the ready modal in this app run.
  final bool dismissedThisSession;

  bool get hasUpdate => phase != UpdatePhase.hidden;

  /// 0..1, or null while the total size is unknown.
  double? get progress {
    if (phase != UpdatePhase.downloading || totalBytes <= 0) return null;
    return (receivedBytes / totalBytes).clamp(0.0, 1.0);
  }

  UpdateState copyWith({
    UpdatePhase? phase,
    AppRelease? release,
    ReleaseAsset? apk,
    ReleaseAsset? checksum,
    int? receivedBytes,
    int? totalBytes,
    String? errorMessage,
    bool clearError = false,
    bool? dismissedThisSession,
  }) {
    return UpdateState(
      phase: phase ?? this.phase,
      release: release ?? this.release,
      apk: apk ?? this.apk,
      checksum: checksum ?? this.checksum,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      dismissedThisSession: dismissedThisSession ?? this.dismissedThisSession,
    );
  }
}
