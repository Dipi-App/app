import 'app_release.dart';

/// What the header icon and the Settings row need to render.
class UpdateState {
  const UpdateState({this.available, this.checking = false});

  /// The newest release, when it is newer than the installed version.
  final AppRelease? available;

  /// True while a check is in flight.
  final bool checking;

  bool get hasUpdate => available != null;

  UpdateState copyWith({
    AppRelease? available,
    bool? checking,
    bool clearAvailable = false,
  }) {
    return UpdateState(
      available: clearAvailable ? null : (available ?? this.available),
      checking: checking ?? this.checking,
    );
  }
}
