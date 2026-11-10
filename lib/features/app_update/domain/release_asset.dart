/// One file attached to a GitHub release.
class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.sizeInBytes,
    required this.downloadUrl,
    this.sha256,
  });

  final String name;
  final int sizeInBytes;
  final String downloadUrl;

  /// Lower-case SHA-256 from GitHub's `digest` field, when it publishes one.
  final String? sha256;

  bool get isApk => name.toLowerCase().endsWith('.apk');

  bool get isChecksum => name.toLowerCase().endsWith('.sha256');

  factory ReleaseAsset.fromJson(Map<String, Object?> json) {
    final digest = (json['digest'] as String? ?? '').trim().toLowerCase();
    return ReleaseAsset(
      name: (json['name'] as String? ?? '').trim(),
      sizeInBytes: (json['size'] as num?)?.toInt() ?? 0,
      downloadUrl: (json['browser_download_url'] as String? ?? '').trim(),
      sha256: digest.startsWith('sha256:') ? digest.substring(7) : null,
    );
  }
}
