/// A released version of the app, as `major.minor.patch`.
///
/// Ordering is the whole point of this type. The versions arrive as strings
/// and comparing those directly puts `1.10.0` before `1.9.0`, which would
/// quietly hide a release from everyone who skipped one.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch);

  /// Reads `major.minor.patch`, and nothing else.
  ///
  /// A build suffix such as `+4` is refused rather than ignored: this type
  /// orders releases, and two versions that differ only by build number are
  /// the same release as far as a reader is concerned.
  factory AppVersion.parse(String value) {
    final match = _pattern.firstMatch(value.trim());
    if (match == null) {
      throw FormatException('Not a major.minor.patch version', value);
    }

    return AppVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  /// Returns null instead of throwing, for a stored value that may predate
  /// this feature or have been written by hand.
  static AppVersion? tryParse(String? value) {
    if (value == null) return null;
    try {
      return AppVersion.parse(value);
    } on FormatException {
      return null;
    }
  }

  static final _pattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');

  final int major;
  final int minor;
  final int patch;

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator >(AppVersion other) => compareTo(other) > 0;
  bool operator <(AppVersion other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
