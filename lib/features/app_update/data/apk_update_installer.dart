import 'dart:async';

import 'package:flutter/services.dart';

/// The stages the native updater reports while it works.
enum ApkInstallStage { downloading, verifying, waiting, installed, failed }

class ApkInstallEvent {
  const ApkInstallEvent({
    required this.stage,
    this.percent = 0,
    this.message,
    this.version,
  });

  final ApkInstallStage stage;

  /// 0–100 while downloading; 100 once the file is verified.
  final int percent;

  /// A Persian reason, when the stage is [ApkInstallStage.failed].
  final String? message;

  /// The release version this event belongs to.
  final String? version;
}

/// Talks to the `dipi/update` channel (`ApkUpdates.kt`).
///
/// The APK is downloaded by the app only after the user taps install. Before
/// anything is handed to Android's installer, the native side checks that the
/// file is Dipi, has a higher versionCode and is signed with this install's
/// certificate. Android then shows its own confirmation.
class ApkUpdateInstaller {
  static const MethodChannel _channel = MethodChannel('dipi/update');

  final StreamController<ApkInstallEvent> _events =
      StreamController<ApkInstallEvent>.broadcast();

  Stream<ApkInstallEvent> get events => _events.stream;

  /// The latest event, so a dialog reopened mid-download shows the truth
  /// instead of offering a second download.
  ApkInstallEvent? get lastEvent => _lastEvent;
  ApkInstallEvent? _lastEvent;

  ApkUpdateInstaller() {
    _channel.setMethodCallHandler(_handle);
  }

  Future<Object?> _handle(MethodCall call) async {
    if (call.method != 'installProgress') return null;
    final args = call.arguments;
    if (args is! Map) return null;
    final stage = switch (args['stage']) {
      'downloading' => ApkInstallStage.downloading,
      'verifying' => ApkInstallStage.verifying,
      'waiting' => ApkInstallStage.waiting,
      'installed' => ApkInstallStage.installed,
      'failed' => ApkInstallStage.failed,
      _ => null,
    };
    if (stage == null) return null;
    final percent = (args['percent'] as num?)?.round().clamp(0, 100) ?? 0;
    final message = args['message'] as String?;
    final version = args['version'] as String?;
    final event = ApkInstallEvent(
      stage: stage,
      percent: percent,
      message: message,
      version: version,
    );
    _lastEvent = event;
    _events.add(event);
    return null;
  }

  /// Whether Android currently allows this app to install packages.
  Future<bool> canInstall() async {
    try {
      return await _channel.invokeMethod<bool>('canInstall') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system screen where "install unknown apps" is allowed.
  Future<bool> openInstallSettings() async {
    try {
      return await _channel.invokeMethod<bool>('openInstallSettings') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// The device's primary ABI, so a 64-bit phone gets the smaller APK.
  Future<String?> supportedAbi() async {
    try {
      final abi = await _channel.invokeMethod<String>('supportedAbi');
      return (abi == null || abi.isEmpty) ? null : abi;
    } catch (_) {
      return null;
    }
  }

  /// Starts the download. Returns false when it could not start at all;
  /// progress and failures arrive on [events].
  Future<bool> start({
    required Uri url,
    required String version,
    String? sha256,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('installUpdate', {
            'url': url.toString(),
            'version': version,
            'sha256': sha256 ?? '',
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
    _events.close();
  }
}
