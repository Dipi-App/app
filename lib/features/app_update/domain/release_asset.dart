/// One file attached to a GitHub release.
class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.sizeInBytes,
    required this.downloadUrl,
  });

  final String name;
  final int sizeInBytes;
  final String downloadUrl;

  bool get isApk => name.toLowerCase().endsWith('.apk');

  bool get isChecksum => name.toLowerCase().endsWith('.sha256');

  factory ReleaseAsset.fromJson(Map<String, Object?> json) => ReleaseAsset(
    name: (json['name'] as String? ?? '').trim(),
    sizeInBytes: (json['size'] as num?)?.toInt() ?? 0,
    downloadUrl: (json['browser_download_url'] as String? ?? '').trim(),
  );
}
