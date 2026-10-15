import 'package:flutter/services.dart';

import '../domain/update_config.dart';

/// Opens a web link in the system browser.
///
/// A tiny platform channel (`dipi/update`, see `MainActivity.kt`) hands the URL
/// to the browser. No plugin and no permission are needed: the browser performs
/// the APK download and the "install from this source" step, so Dipi itself
/// never requests to install packages.
class UrlLauncherChannel {
  static const MethodChannel _channel = MethodChannel('dipi/update');

  /// Returns true when the browser was opened. Refuses any host that is not on
  /// the [UpdateConfig.allowedLinkHosts] allow-list.
  Future<bool> open(Uri url) async {
    if (!UpdateConfig.isAllowedLinkUrl(url)) return false;
    try {
      return await _channel.invokeMethod<bool>(
            'openUrl',
            {'url': url.toString()},
          ) ??
          false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
