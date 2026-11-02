/// Model untuk metadata update dari active.json
class UpdateMetadata {
  final int releaseVersion;
  final int schemaVersion;
  final String minAppVersion;
  final String channel;
  final DateTime releasedAt;
  final DatabaseInfo database;
  final String manifestUrl;

  UpdateMetadata({
    required this.releaseVersion,
    required this.schemaVersion,
    required this.minAppVersion,
    required this.channel,
    required this.releasedAt,
    required this.database,
    required this.manifestUrl,
  });

  factory UpdateMetadata.fromJson(Map<String, dynamic> json) {
    return UpdateMetadata(
      releaseVersion: json['release_version'] as int,
      schemaVersion: json['schema_version'] as int,
      minAppVersion: json['min_app_version'] as String,
      channel: json['channel'] as String,
      releasedAt: DateTime.parse(json['released_at'] as String),
      database: DatabaseInfo.fromJson(json['database'] as Map<String, dynamic>),
      manifestUrl: json['manifest_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'release_version': releaseVersion,
      'schema_version': schemaVersion,
      'min_app_version': minAppVersion,
      'channel': channel,
      'released_at': releasedAt.toIso8601String(),
      'database': database.toJson(),
      'manifest_url': manifestUrl,
    };
  }

  @override
  String toString() =>
      'UpdateMetadata(version: $releaseVersion, schema: $schemaVersion, channel: $channel)';
}

/// Model untuk informasi database dari active.json
class DatabaseInfo {
  final String file;
  final String url;
  final int size;
  final String sha256;

  DatabaseInfo({
    required this.file,
    required this.url,
    required this.size,
    required this.sha256,
  });

  factory DatabaseInfo.fromJson(Map<String, dynamic> json) {
    return DatabaseInfo(
      file: json['file'] as String,
      url: json['url'] as String,
      size: json['size'] as int,
      sha256: json['sha256'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'file': file, 'url': url, 'size': size, 'sha256': sha256};
  }

  @override
  String toString() =>
      'DatabaseInfo(file: $file, size: $size, sha256: ${sha256.substring(0, 8)}...)';
}
