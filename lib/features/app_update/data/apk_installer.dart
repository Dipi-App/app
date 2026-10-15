import 'dart:io';

import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

/// Opens the Android "install from unknown sources" page for this app.
///
/// `open_filex` cannot open that settings screen, so a tiny method channel
/// (`dipi/update`, see `MainActivity.kt`) does it.
class ApkInstaller {
  static const MethodChannel _channel = MethodChannel('dipi/update');

  /// Whether the app is allowed to start an install right now (Android 8+).
  Future<bool> canInstall() async {
    try {
      return await _channel.invokeMethod<bool>('canInstallPackages') ?? true;
    } on MissingPluginException {
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<void> openInstallSettings() async {
    try {
      await _channel.invokeMethod<void>('openInstallSettings');
    } catch (_) {}
  }

  /// Hands the APK to the system package installer. True when it started.
  Future<bool> launch(File apk) async {
    final result = await OpenFilex.open(
      apk.path,
      type: 'application/vnd.android.package-archive',
    );
    return result.type == ResultType.done;
  }
}
