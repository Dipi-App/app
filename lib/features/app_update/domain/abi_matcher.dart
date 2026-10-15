import 'app_release.dart';
import 'release_asset.dart';

/// Picks the APK that matches the device.
///
/// [supportedAbis] comes from `device_info_plus`, best-first (for example
/// `arm64-v8a`, then `armeabi-v7a`). Assets are named
/// `dipi-v1.2.0-arm64-v8a.apk`, so an exact ABI suffix match wins. If the phone
/// has no matching ABI, the `universal` APK is used.
ReleaseAsset? pickApkForAbis(AppRelease release, List<String> supportedAbis) {
  final apks = release.apks;
  if (apks.isEmpty) return null;

  for (final abi in supportedAbis) {
    final normalized = abi.trim().toLowerCase();
    if (normalized.isEmpty) continue;
    for (final apk in apks) {
      if (apk.name.toLowerCase().endsWith('-$normalized.apk')) return apk;
    }
  }

  final universal = release.universalApk;
  if (universal != null) return universal;

  // No ABI match and no universal asset: a single APK is the only option.
  return apks.length == 1 ? apks.first : null;
}
