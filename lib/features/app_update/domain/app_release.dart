import 'release_asset.dart';
import 'semantic_version.dart';

/// A GitHub release we can install from.
class AppRelease {
  const AppRelease({
    required this.tag,
    required this.version,
    required this.body,
    required this.assets,
  });

  /// The raw tag, e.g. `v1.2.0`.
  final String tag;

  final SemanticVersion version;

  /// The release notes (markdown body, may be empty).
  final String body;

  final List<ReleaseAsset> assets;

  List<ReleaseAsset> get apks =>
      assets.where((asset) => asset.isApk).toList(growable: false);

  ReleaseAsset? get universalApk {
    for (final asset in apks) {
      if (asset.name.endsWith('-universal.apk')) return asset;
    }
    return null;
  }

  /// The `.sha256` file that belongs to [apk], if the release has one.
  ReleaseAsset? checksumFor(ReleaseAsset apk) {
    final wanted = '${apk.name}.sha256';
    for (final asset in assets) {
      if (asset.isChecksum && asset.name == wanted) return asset;
    }
    return null;
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
      assets: assets,
    );
  }
}
