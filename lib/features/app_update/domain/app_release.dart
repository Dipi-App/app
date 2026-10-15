import 'release_asset.dart';
import 'semantic_version.dart';
import 'update_config.dart';

/// A GitHub release the app can point the user at.
class AppRelease {
  const AppRelease({
    required this.tag,
    required this.version,
    required this.body,
    required this.assets,
    this.htmlUrl = '',
  });

  /// The raw tag, e.g. `v1.2.0`.
  final String tag;

  final SemanticVersion version;

  /// The release notes (markdown body, may be empty).
  final String body;

  /// The public page on GitHub for this release.
  final String htmlUrl;

  final List<ReleaseAsset> assets;

  List<ReleaseAsset> get apks =>
      assets.where((asset) => asset.isApk).toList(growable: false);

  /// The universal APK, named `dipi-<version>.apk` (older releases used the
  /// `-universal.apk` suffix).
  ReleaseAsset? get universalApk {
    for (final asset in apks) {
      final name = asset.name.toLowerCase();
      if (name == 'dipi-$version.apk' || name.endsWith('-universal.apk')) {
        return asset;
      }
    }
    return null;
  }

  /// The APK to download: the universal one, else any APK.
  ReleaseAsset? get bestApk {
    final universal = universalApk;
    if (universal != null) return universal;
    return apks.isEmpty ? null : apks.first;
  }

  /// Where the "download" button should send the browser.
  String get downloadUrl {
    final apk = bestApk;
    if (apk != null && apk.downloadUrl.isNotEmpty) return apk.downloadUrl;
    if (htmlUrl.isNotEmpty) return htmlUrl;
    return UpdateConfig.releasesPageUrl;
  }

  factory AppRelease.fromJson(Map<String, Object?> json) {
    final tag = (json['tag_name'] as String? ?? '').trim();
    final assets = (json['assets'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => ReleaseAsset.fromJson(item.cast<String, Object?>()))
        .toList(growable: false);
    return AppRelease(
      tag: tag,
      version: SemanticVersion.tryParse(tag) ?? const SemanticVersion(0, 0, 0),
      body: (json['body'] as String? ?? '').trim(),
      htmlUrl: (json['html_url'] as String? ?? '').trim(),
      assets: assets,
    );
  }
}
