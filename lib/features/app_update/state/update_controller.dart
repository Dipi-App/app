import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_info_providers.dart';
import '../../settings/state/settings_providers.dart';
import '../data/github_release_client.dart';
import '../domain/app_release.dart';
import '../domain/check_schedule.dart';
import '../domain/semantic_version.dart';
import '../domain/update_config.dart';
import '../domain/update_state.dart';
import 'update_providers.dart';

/// The outcome of a check, so the caller can pick the right message.
enum CheckOutcome {
  /// A newer version was found.
  found,

  /// The installed version is current.
  upToDate,

  /// The window has not passed yet (automatic checks only).
  skipped,

  /// No internet, or the API answered with an error. Always handled quietly.
  offLine,
}

/// The result of a check: the outcome plus the release, when one was found.
class CheckResult {
  const CheckResult(this.outcome, [this.release]);

  final CheckOutcome outcome;
  final AppRelease? release;
}

/// Checks GitHub Releases for a newer version and remembers the newest one.
///
/// It never downloads or installs anything: the user is sent to the APK in the
/// browser. The whole flow stays offline-safe — any network error is swallowed
/// and reported only to the caller, never as a crash.
class UpdateController extends Notifier<UpdateState> {
  @override
  UpdateState build() => const UpdateState();

  /// Runs once when the home screen appears: checks at most every 24 hours.
  Future<CheckResult> onAppStart() => check(manual: false);

  Future<CheckResult> check({required bool manual}) async {
    if (state.checking) return CheckResult(CheckOutcome.skipped, state.available);

    final settings = ref.read(settingsValueProvider);
    final now = DateTime.now();
    if (!isCheckDue(
      now: now,
      lastCheck: settings.lastUpdateCheckDate,
      interval: UpdateConfig.checkInterval,
      manual: manual,
    )) {
      return CheckResult(CheckOutcome.skipped, state.available);
    }

    state = state.copyWith(checking: true);

    final AppRelease? release;
    try {
      release = await ref.read(githubReleaseClientProvider).latest();
    } on GitHubReleaseException {
      state = state.copyWith(checking: false);
      return const CheckResult(CheckOutcome.offLine);
    } catch (_) {
      state = state.copyWith(checking: false);
      return const CheckResult(CheckOutcome.offLine);
    }

    // A real answer came back; remember it even when there is no new version.
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .setLastUpdateCheckAt(now);
    } catch (_) {}

    final installed = await _installedVersion();
    if (release != null && release.version > installed) {
      state = UpdateState(available: release);
      return CheckResult(CheckOutcome.found, release);
    }

    state = const UpdateState();
    return const CheckResult(CheckOutcome.upToDate);
  }

  /// Opens the release's APK (or its page) in the browser.
  Future<bool> openDownload(AppRelease release) {
    return ref.read(urlLauncherProvider).open(Uri.parse(release.downloadUrl));
  }

  Future<SemanticVersion> _installedVersion() async {
    try {
      final raw = await ref.read(appVersionProvider.future);
      return SemanticVersion.tryParse(raw) ?? const SemanticVersion(0, 0, 0);
    } catch (_) {
      return const SemanticVersion(0, 0, 0);
    }
  }
}
