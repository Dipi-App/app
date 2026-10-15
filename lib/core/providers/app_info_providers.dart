import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/app_info.dart';

/// The installed app version, e.g. `1.0.0+1`.
///
/// Falls back to the compile-time [AppInfo.version] when the platform channel
/// is unavailable (for example in widget tests).
final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    final build = info.buildNumber.trim();
    return build.isEmpty ? info.version : '${info.version}+$build';
  } catch (_) {
    return AppInfo.version;
  }
});
