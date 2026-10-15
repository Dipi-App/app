/// A small semantic version (`MAJOR.MINOR.PATCH` with an optional `+BUILD`).
///
/// Real numeric compare, not string compare: `1.10.0` is newer than `1.9.0`.
/// A leading `v` and any `-prerelease` / `+build` metadata are understood.
class SemanticVersion implements Comparable<SemanticVersion> {
  const SemanticVersion(this.major, this.minor, this.patch, [this.build = 0]);

  final int major;
  final int minor;
  final int patch;
  final int build;

  /// Parses `v1.2.3`, `1.2.3`, `1.2.3+4`, `1.2.3-rc.1`. Returns null when the
  /// text does not look like a version.
  static SemanticVersion? tryParse(String? raw) {
    if (raw == null) return null;
    var text = raw.trim();
    if (text.isEmpty) return null;
    if (text.startsWith('v') || text.startsWith('V')) {
      text = text.substring(1);
    }
    // Drop build metadata and pre-release suffixes before splitting.
    text = text.split('+').first.split('-').first;

    final parts = text.split('.');
    if (parts.isEmpty) return null;

    int? at(int index) =>
        index < parts.length ? int.tryParse(parts[index].trim()) : 0;

    final major = int.tryParse(parts[0].trim());
    if (major == null) return null;
    final build = _buildOf(raw);
    return SemanticVersion(major, at(1) ?? 0, at(2) ?? 0, build);
  }

  static int _buildOf(String raw) {
    final plus = raw.indexOf('+');
    if (plus == -1) return 0;
    final tail = raw.substring(plus + 1);
    final digits = RegExp(r'^\d+').stringMatch(tail);
    return digits == null ? 0 : int.parse(digits);
  }

  @override
  int compareTo(SemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    return build.compareTo(other.build);
  }

  bool operator >(SemanticVersion other) => compareTo(other) > 0;

  bool operator <(SemanticVersion other) => compareTo(other) < 0;

  bool operator >=(SemanticVersion other) => compareTo(other) >= 0;

  bool operator <=(SemanticVersion other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      other is SemanticVersion &&
      major == other.major &&
      minor == other.minor &&
      patch == other.patch &&
      build == other.build;

  @override
  int get hashCode => Object.hash(major, minor, patch, build);

  @override
  String toString() => build > 0 ? '$major.$minor.$patch+$build' : '$major.$minor.$patch';
}
