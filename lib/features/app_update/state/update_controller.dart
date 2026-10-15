import 'dart:async';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_info_providers.dart';
import '../../settings/state/settings_providers.dart';
import '../data/checksum.dart';
import '../data/github_release_client.dart';
import '../data/update_download_service.dart';
import '../data/update_storage.dart';
import '../domain/abi_matcher.dart';
import '../domain/app_release.dart';
import '../domain/check_schedule.dart';
import '../domain/release_asset.dart';
import '../domain/semantic_version.dart';
import '../domain/update_machine.dart';
import '../domain/update_phase.dart';
import '../domain/update_state.dart';
import 'update_providers.dart';

/// Result of a version check, so the Settings button can show one short line.
enum CheckOutcome { found, upToDate, skipped, offLine, rateLimited, busy }

/// Result of asking to install.
enum InstallOutcome { started, needsPermission, invalidFile, failed }

class UpdateController extends Notifier<UpdateState> {
  CancelToken? _cancelToken;
  StoredUpdate? _stored;
  bool _downloading = false;
  bool _cancelled = false;

  @override
  UpdateState build() => const UpdateState();

  bool get isDownloading => _downloading;

  /// Runs once when the home screen appears: settle any finished download,
  /// resume a partial one, then check for a new release if the window passed.
  Future<void> onAppStart() async {
    await _reconcileInstalled();
    // A half-finished download resumes right away (Wi-Fi rules still apply);
    // this does not need a fresh network check.
    if (state.phase == UpdatePhase.available) {
      await startDownload();
    }
    await checkForUpdates(manual: false);
  }

  Future<CheckOutcome> checkForUpdates({required bool manual}) async {
    if (_downloading) return CheckOutcome.busy;

    final settings = ref.read(settingsValueProvider);
    final now = DateTime.now();
    final last = settings.lastUpdateCheckAt == null
        ? null
        : DateTime.tryParse(settings.lastUpdateCheckAt!);
    if (!isCheckDue(now: now, lastCheck: last, manual: manual)) {
      return CheckOutcome.skipped;
    }

    final AppRelease? release;
    try {
      release = await ref.read(githubReleaseClientProvider).latest();
    } on GitHubReleaseException catch (error) {
      return error.rateLimited ? CheckOutcome.rateLimited : CheckOutcome.offLine;
    } catch (_) {
      return CheckOutcome.offLine;
    }

    // A real answer came back; remember it even when there is no new version.
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .setLastUpdateCheckAt(now);
    } catch (_) {}

    final installed = await _installedVersion();
    if (release == null || !(release.version > installed)) {
      if (state.phase != UpdatePhase.ready) {
        state = state.copyWith(phase: UpdatePhase.hidden, clearError: true);
      }
      return CheckOutcome.upToDate;
    }

    final abis = await ref.read(deviceAbisProvider.future);
    final apk = pickApkForAbis(release, abis);
    if (apk == null) {
      state = state.copyWith(phase: UpdatePhase.hidden, clearError: true);
      return manual ? CheckOutcome.offLine : CheckOutcome.upToDate;
    }
    final checksum = release.checksumFor(apk);

    // A verified copy of this exact version may already be on disk.
    final pending = await ref.read(updateStorageProvider).loadPending();
    if (pending != null &&
        pending.complete &&
        pending.filePresent &&
        SemanticVersion.tryParse(pending.version) == release.version) {
      _stored = pending;
      state = _stateFromStored(pending, UpdatePhase.ready);
      return CheckOutcome.found;
    }

    final network = await ref.read(connectivityServiceProvider).status();
    final target = UpdateTarget(apk: apk, checksum: checksum);
    final existingBytes = pending != null && !pending.complete
        ? pending.existingBytes
        : 0;
    var next = UpdateMachine.afterCheck(
      state,
      release: release,
      onWifi: network.onWifi,
      wifiOnly: settings.autoUpdateWifiOnly,
    );
    next = UpdateMachine.withTarget(
      next,
      target: target,
      existingBytes: existingBytes,
    );
    state = next;

    if (next.phase == UpdatePhase.downloading) {
      unawaited(_downloadInBackground());
    }
    return CheckOutcome.found;
  }

  /// Starts (or resumes) the download. [force] is used when the user taps
  /// "دانلود" on mobile data.
  Future<void> startDownload({bool force = false}) async {
    if (_downloading || state.phase == UpdatePhase.ready) return;

    if (state.release == null || state.apk == null) {
      await checkForUpdates(manual: true);
      return;
    }

    final settings = ref.read(settingsValueProvider);
    final network = await ref.read(connectivityServiceProvider).status();
    final metered =
        network.onMobile && settings.autoUpdateWifiOnly && !network.onWifi;
    if (metered && !force) {
      state = state.copyWith(phase: UpdatePhase.available, clearError: true);
      return;
    }

    state = UpdateMachine.onStartAgain(state);
    await _downloadInBackground();
  }

  void cancelDownload() {
    _cancelled = true;
    _cancelToken?.cancel('user');
    _cancelToken = null;
    _downloading = false;
    state = UpdateMachine.onCancelled(state);
  }

  void dismissModal() {
    state = UpdateMachine.onDismissed(state);
  }

  Future<void> retry() async {
    if (state.phase != UpdatePhase.error) return;
    if (state.release != null && state.apk != null) {
      state = UpdateMachine.onStartAgain(state);
      await _downloadInBackground();
    } else {
      await checkForUpdates(manual: true);
    }
  }

  Future<InstallOutcome> install() async {
    final storage = ref.read(updateStorageProvider);
    var stored = _stored;
    stored ??= await storage.loadPending();
    if (stored == null || !stored.complete || !stored.filePresent) {
      state = UpdateMachine.onError(state, 'فایل نصب پیدا نشد.');
      return InstallOutcome.invalidFile;
    }

    final downloader = ref.read(updateDownloadServiceProvider);
    final actual = await downloader.hashOfFile(stored.apkFile);
    if (stored.expectedSha.isEmpty ||
        !checksumMatches(actual, stored.expectedSha)) {
      await storage.deleteAll();
      _stored = null;
      state = UpdateMachine.onError(state, 'فایل سالم نبود. دوباره بگیر.');
      return InstallOutcome.invalidFile;
    }

    final installer = ref.read(apkInstallerProvider);
    if (!await installer.canInstall()) return InstallOutcome.needsPermission;

    if (await installer.launch(stored.apkFile)) return InstallOutcome.started;
    state = UpdateMachine.onError(state, 'شروع نصب ممکن نشد. دوباره تلاش کن.');
    return InstallOutcome.failed;
  }

  // ---- internals ----

  Future<void> _downloadInBackground() async {
    if (_downloading) return;
    final release = state.release;
    final apk = state.apk;
    if (release == null || apk == null) return;
    final checksum = state.checksum;

    _downloading = true;
    _cancelled = false;
    final storage = ref.read(updateStorageProvider);
    final downloader = ref.read(updateDownloadServiceProvider);
    final token = CancelToken();
    _cancelToken = token;

    StoredUpdate? stored;
    try {
      stored = await storage.begin(
        tag: release.tag,
        version: release.version.toString(),
        notes: release.body,
        apk: apk,
        checksum: checksum,
      );
      _stored = stored;
      state = UpdateMachine.withTarget(
        state,
        target: UpdateTarget(apk: apk, checksum: checksum),
        existingBytes: stored.existingBytes,
      );
      await downloader.download(
        url: Uri.parse(stored.url),
        file: stored.apkFile,
        cancelToken: token,
        onProgress: (received, total) =>
            state = UpdateMachine.onProgress(state, received, total),
      );
    } on UpdateDownloadException catch (error) {
      if (!_cancelled) {
        state = UpdateMachine.onError(state, error.message);
      }
      return;
    } catch (_) {
      if (!_cancelled) {
        state = UpdateMachine.onError(state, 'دانلود انجام نشد.');
      }
      return;
    } finally {
      _cancelToken = null;
      _downloading = false;
    }

    if (_cancelled) return;
    await _verify(stored, downloader, storage);
  }

  Future<void> _verify(
    StoredUpdate stored,
    UpdateDownloadService downloader,
    UpdateStorage storage,
  ) async {
    if (stored.checksumUrl.isEmpty) {
      await storage.deleteAll();
      _stored = null;
      state = UpdateMachine.onError(
        state,
        'فایل «بررسی سالم بودن» در این نسخه نبود. نصب انجام نشد.',
      );
      return;
    }
    final String expected;
    try {
      expected = await downloader.fetchChecksum(Uri.parse(stored.checksumUrl));
    } catch (_) {
      state = UpdateMachine.onError(
        state,
        'سالم بودن فایل بررسی نشد. دوباره تلاش کن.',
      );
      return;
    }
    final actual = await downloader.hashOfFile(stored.apkFile);
    if (!checksumMatches(actual, expected)) {
      await storage.deleteAll();
      _stored = null;
      state = UpdateMachine.onError(
        state,
        'فایل دانلود‌شده سالم نبود. دوباره تلاش کن.',
      );
      return;
    }
    await storage.markVerified(stored, expected);
    // Re-read so the in-memory handle carries complete=true and the hash.
    _stored = await storage.loadPending() ?? stored;
    state = UpdateMachine.onDownloaded(state);
  }

  Future<void> _reconcileInstalled() async {
    final storage = ref.read(updateStorageProvider);
    final stored = await storage.loadPending();
    if (stored == null) return;

    final installed = await _installedVersion();
    final version = SemanticVersion.tryParse(stored.version);
    if (version == null) {
      await storage.deleteAll();
      return;
    }

    if (version <= installed) {
      final wasComplete = stored.complete;
      await storage.deleteAll();
      if (wasComplete) {
        ref
            .read(updateInstalledNoticeProvider.notifier)
            .show(stored.version);
      }
      return;
    }

    _stored = stored;
    state = _stateFromStored(
      stored,
      stored.complete && stored.filePresent
          ? UpdatePhase.ready
          : UpdatePhase.available,
    );
  }

  UpdateState _stateFromStored(StoredUpdate stored, UpdatePhase phase) {
    final version =
        SemanticVersion.tryParse(stored.version) ?? const SemanticVersion(0, 0, 0);
    final apk = ReleaseAsset(
      name: stored.apkName,
      sizeInBytes: stored.expectedBytes,
      downloadUrl: stored.url,
    );
    final checksum = stored.checksumUrl.isEmpty
        ? null
        : ReleaseAsset(
            name: '${stored.apkName}.sha256',
            sizeInBytes: 0,
            downloadUrl: stored.checksumUrl,
          );
    final release = AppRelease(
      tag: stored.tag.isEmpty ? 'v$version' : stored.tag,
      version: version,
      body: stored.notes,
      assets: [apk, ?checksum],
    );
    return UpdateState(
      phase: phase,
      release: release,
      apk: apk,
      checksum: checksum,
      receivedBytes: stored.existingBytes,
      totalBytes: stored.expectedBytes,
      dismissedThisSession: state.dismissedThisSession,
    );
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

/// Holds the "just installed" version until the UI shows it once.
class UpdateInstalledNotice extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String version) => state = version;

  void clear() => state = null;
}
