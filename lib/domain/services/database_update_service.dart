import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/datasources/network_source.dart';
import '../../data/local/kamus_database_installer.dart';
import '../../data/repositories/app_metadata_repository.dart';
import '../../data/repositories/kamus_repository.dart';
import '../../models/update_metadata.dart';
import '../../utils/constants.dart';
import '../../utils/version.dart';

/// Tahapan proses pemasangan database.
enum DatabaseUpdatePhase { checking, downloading, verifying, installing }

/// Progres pemasangan database yang dapat ditampilkan di UI.
class DatabaseUpdateProgress {
  final DatabaseUpdatePhase phase;
  final String message;
  final int received;
  final int? total;

  const DatabaseUpdateProgress({
    required this.phase,
    required this.message,
    this.received = 0,
    this.total,
  });

  double? get fraction {
    if (phase != DatabaseUpdatePhase.downloading) return null;
    final size = total;
    if (size == null || size <= 0) return null;
    return (received / size).clamp(0.0, 1.0).toDouble();
  }
}

/// Hasil proses pemasangan database.
class DatabaseUpdateOutcome {
  final bool success;
  final bool alreadyLatest;
  final UpdateMetadata? metadata;
  final String? error;

  const DatabaseUpdateOutcome._({
    required this.success,
    required this.alreadyLatest,
    this.metadata,
    this.error,
  });

  factory DatabaseUpdateOutcome.success(UpdateMetadata metadata) =>
      DatabaseUpdateOutcome._(
        success: true,
        alreadyLatest: false,
        metadata: metadata,
      );

  factory DatabaseUpdateOutcome.alreadyLatest(UpdateMetadata metadata) =>
      DatabaseUpdateOutcome._(
        success: true,
        alreadyLatest: true,
        metadata: metadata,
      );

  factory DatabaseUpdateOutcome.failure(String message) =>
      DatabaseUpdateOutcome._(
        success: false,
        alreadyLatest: false,
        error: message,
      );
}

/// Layanan unduh, verifikasi, dan pemasangan database kamus.
class DatabaseUpdateService {
  final NetworkSource network;
  final KamusRepository kamusRepository;
  final KamusDatabaseInstaller installer;
  final AppMetadataRepository appMetadata;
  final Future<Directory> Function() temporaryDirectory;

  DatabaseUpdateService({
    required this.network,
    required this.kamusRepository,
    required this.installer,
    required this.appMetadata,
    Future<Directory> Function()? temporaryDirectory,
  }) : temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  /// Unduh rilis terbaru dari metadata aktif, verifikasi, lalu pasang.
  Future<DatabaseUpdateOutcome> installLatest({
    required String currentAppVersion,
    void Function(DatabaseUpdateProgress progress)? onProgress,
  }) async {
    Directory? workDir;
    File? downloaded;

    void report(DatabaseUpdateProgress progress) => onProgress?.call(progress);

    try {
      report(
        const DatabaseUpdateProgress(
          phase: DatabaseUpdatePhase.checking,
          message: 'Memeriksa versi terbaru...',
        ),
      );

      final metadata = await network.fetchActiveMetadata();

      if (metadata.schemaVersion != AppConstants.supportedSchemaVersion) {
        return DatabaseUpdateOutcome.failure(
          'Database memakai skema v${metadata.schemaVersion}, sedangkan '
          'aplikasi ini mendukung skema v'
          '$AppConstants.supportedSchemaVersion. Perbarui aplikasi.',
        );
      }

      if (!isVersionAtLeast(currentAppVersion, metadata.minAppVersion)) {
        return DatabaseUpdateOutcome.failure(
          'Versi aplikasi $currentAppVersion terlalu lama untuk database '
          'terbaru. Perbarui aplikasi ke versi ${metadata.minAppVersion} '
          'atau lebih baru.',
        );
      }

      final installed = await _installedReleaseVersion();
      if (installed >= metadata.releaseVersion) {
        await appMetadata.setLastUpdateCheck(_nowSeconds());
        return DatabaseUpdateOutcome.alreadyLatest(metadata);
      }

      final temp = await temporaryDirectory();
      workDir = Directory(p.join(temp.path, 'kamus_update'));
      if (!await workDir.exists()) {
        await workDir.create(recursive: true);
      }

      final fileName = p.basename(metadata.database.file);
      downloaded = File(p.join(workDir.path, fileName));

      report(
        DatabaseUpdateProgress(
          phase: DatabaseUpdatePhase.downloading,
          message: 'Mengunduh database v${metadata.releaseVersion}...',
          total: metadata.database.size,
        ),
      );

      await network.downloadFile(
        uri: Uri.parse(metadata.database.url),
        destination: downloaded,
        onProgress: (received, total) => report(
          DatabaseUpdateProgress(
            phase: DatabaseUpdatePhase.downloading,
            message: 'Mengunduh database v${metadata.releaseVersion}...',
            received: received,
            total: total ?? metadata.database.size,
          ),
        ),
      );

      report(
        const DatabaseUpdateProgress(
          phase: DatabaseUpdatePhase.verifying,
          message: 'Memeriksa keutuhan file...',
        ),
      );

      final length = await downloaded.length();
      if (metadata.database.size > 0 && length != metadata.database.size) {
        return DatabaseUpdateOutcome.failure(
          'Ukuran file tidak sesuai ($length dari '
          '${metadata.database.size} byte).',
        );
      }

      final digest = await sha256.bind(downloaded.openRead()).first;
      if (digest.toString().toLowerCase() !=
          metadata.database.sha256.toLowerCase()) {
        return DatabaseUpdateOutcome.failure(
          'Checksum database tidak cocok. File mungkin rusak atau tidak '
          'lengkap.',
        );
      }

      report(
        const DatabaseUpdateProgress(
          phase: DatabaseUpdatePhase.installing,
          message: 'Memasang database...',
        ),
      );

      final installResult = await installer.installFromGzip(downloaded);
      if (!installResult.success) {
        return DatabaseUpdateOutcome.failure(
          installResult.errorMessage ?? 'Instalasi database gagal.',
        );
      }

      await appMetadata.setDbVersion(metadata.releaseVersion.toString());
      await appMetadata.setLastUpdateCheck(_nowSeconds());

      return DatabaseUpdateOutcome.success(metadata);
    } on NetworkException catch (e) {
      return DatabaseUpdateOutcome.failure(e.message);
    } on FileSystemException catch (e) {
      return DatabaseUpdateOutcome.failure(
        'Gagal menyiapkan file database: ${e.message}',
      );
    } catch (e) {
      return DatabaseUpdateOutcome.failure('Pemasangan database gagal: $e');
    } finally {
      try {
        if (downloaded != null && await downloaded.exists()) {
          await downloaded.delete();
        }
        if (workDir != null && await workDir.exists()) {
          await workDir.delete(recursive: true);
        }
      } catch (_) {
        // File sementara tidak kritis; biarkan dibersihkan sistem.
      }
    }
  }

  Future<int> _installedReleaseVersion() async {
    try {
      final meta = await kamusRepository.getReleaseMeta();
      return int.tryParse(meta['release_version'] ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  int _nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
