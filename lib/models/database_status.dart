/// Status kesiapan database kamus di perangkat.
enum DatabaseReadiness { notInstalled, invalid, ready }

/// Ringkasan status database untuk ditampilkan di UI.
class DatabaseStatus {
  final DatabaseReadiness readiness;
  final int wordCount;
  final int? releaseVersion;
  final int? schemaVersion;
  final String? releasedAt;
  final String? channel;
  final String? errorMessage;

  const DatabaseStatus({
    required this.readiness,
    this.wordCount = 0,
    this.releaseVersion,
    this.schemaVersion,
    this.releasedAt,
    this.channel,
    this.errorMessage,
  });

  bool get isReady => readiness == DatabaseReadiness.ready;

  factory DatabaseStatus.notInstalled() =>
      const DatabaseStatus(readiness: DatabaseReadiness.notInstalled);

  factory DatabaseStatus.invalid(String message) => DatabaseStatus(
    readiness: DatabaseReadiness.invalid,
    errorMessage: message,
  );

  @override
  String toString() =>
      'DatabaseStatus(readiness: $readiness, words: $wordCount, version: $releaseVersion)';
}
