/// Membandingkan dua versi semver sederhana (`major.minor.patch`).
///
/// Nilai build (`+1`) dan suffix pra-rilis diabaikan.
int compareVersions(String a, String b) {
  final left = _parts(a);
  final right = _parts(b);
  final length = left.length > right.length ? left.length : right.length;

  for (var i = 0; i < length; i++) {
    final l = i < left.length ? left[i] : 0;
    final r = i < right.length ? right[i] : 0;
    if (l != r) return l.compareTo(r);
  }
  return 0;
}

/// Apakah [current] memenuhi versi minimum [minimum].
bool isVersionAtLeast(String current, String minimum) =>
    compareVersions(current, minimum) >= 0;

List<int> _parts(String version) {
  final core = version.split('+').first.split('-').first.trim();
  return core
      .split('.')
      .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
}
