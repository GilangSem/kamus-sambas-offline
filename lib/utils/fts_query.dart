/// Membangun query FTS5 yang aman dari input pengguna.
///
/// Setiap token dibungkus tanda kutip (karakter kutip di-escape) dan diberi
/// suffix `*` agar pencarian mendukung sebagian karakter (prefix).
/// Karakter operator FTS (`AND`, `OR`, `NOT`, `-`, `"`) tidak akan
/// ditafsirkan sebagai sintaks karena berada di dalam tanda kutip.
String buildFtsPrefixQuery(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';

  final tokens = trimmed
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .map((t) => t.replaceAll('"', '""'))
      .where((t) => t.isNotEmpty)
      .map((t) => '"$t"*')
      .toList();

  return tokens.join(' ');
}
