import 'dart:io';

import 'package:path/path.dart' as p;

import 'kamus_database_helper.dart';

/// Status instalasi database kamus.
enum KamusInstallStatus {
  /// Belum ada database terpasang.
  notInstalled,

  /// Ada file tetapi tidak lolos validasi.
  invalid,

  /// Terpasang dan valid.
  ready,
}

/// Hasil instalasi database dari file gzip.
class KamusInstallResult {
  final bool success;
  final String? errorMessage;
  final int? schemaVersion;

  const KamusInstallResult._(
    this.success,
    this.errorMessage,
    this.schemaVersion,
  );

  factory KamusInstallResult.success({int? schemaVersion}) =>
      KamusInstallResult._(true, null, schemaVersion);

  factory KamusInstallResult.failure(String message) =>
      KamusInstallResult._(false, message, null);
}

/// Mengelola instalasi database kamus di perangkat.
///
/// Database kamus berasal dari artifact rilis (`.sqlite.gz`) dan dipasang
/// secara atomik: file lama tidak dihapus sebelum file baru tervalidasi.
class KamusDatabaseInstaller {
  final KamusDatabaseHelper helper;

  KamusDatabaseInstaller({KamusDatabaseHelper? helper})
    : helper = helper ?? KamusDatabaseHelper.instance;

  /// Cek status database yang terpasang tanpa mengubah apa pun.
  Future<KamusInstallStatus> checkStatus() async {
    if (!await helper.exists()) {
      return KamusInstallStatus.notInstalled;
    }
    final validation = await helper.validateSchema();
    return validation.isValid
        ? KamusInstallStatus.ready
        : KamusInstallStatus.invalid;
  }

  /// Pasang database kamus dari file `.sqlite.gz`.
  ///
  /// Langkah: dekode gzip → tulis file sementara → validasi → ganti atomik.
  /// Jika salah satu langkah gagal, database lama tetap utuh.
  Future<KamusInstallResult> installFromGzip(File gzipFile) async {
    if (!await gzipFile.exists()) {
      return KamusInstallResult.failure('File database tidak ditemukan.');
    }

    final targetPath = await helper.resolvePath();
    final targetDir = Directory(p.dirname(targetPath));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final tempPath = p.join(targetDir.path, 'kamus.install.tmp');
    final backupPath = '$targetPath.bak';
    final tempFile = File(tempPath);

    try {
      final compressed = await gzipFile.readAsBytes();
      final List<int> decompressed;
      try {
        decompressed = gzip.decode(compressed);
      } catch (e) {
        return KamusInstallResult.failure(
          'File database tidak dapat diekstrak (korup).',
        );
      }

      if (decompressed.isEmpty) {
        return KamusInstallResult.failure('File database kosong.');
      }

      await tempFile.writeAsBytes(decompressed, flush: true);

      // Validasi file sementara sebelum menyentuh database aktif.
      final probe = KamusDatabaseHelper(
        customPath: tempPath,
        databaseFactoryOverride: helper.databaseFactoryOverride,
      );
      final validation = await probe.validateSchema();
      await probe.close();

      if (!validation.isValid) {
        return KamusInstallResult.failure(
          validation.errorMessage ?? 'Database tidak valid.',
        );
      }

      await helper.atomicSwapDatabase(
        newDatabasePath: tempPath,
        backupPath: backupPath,
      );

      return KamusInstallResult.success(
        schemaVersion: validation.schemaVersion,
      );
    } on FileSystemException catch (e) {
      return KamusInstallResult.failure('Gagal menulis database: $e');
    } catch (e) {
      return KamusInstallResult.failure('Instalasi database gagal: $e');
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }
}
