import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kamus_app/data/datasources/kamus_database_source.dart';
import 'package:kamus_app/data/datasources/local_database_source.dart';
import 'package:kamus_app/data/datasources/network_source.dart';
import 'package:kamus_app/data/local/kamus_database_helper.dart';
import 'package:kamus_app/data/local/kamus_database_installer.dart';
import 'package:kamus_app/data/local/local_database_helper.dart';
import 'package:kamus_app/data/repositories/app_metadata_repository.dart';
import 'package:kamus_app/data/repositories/kamus_repository.dart';
import 'package:kamus_app/domain/services/database_update_service.dart';
import 'package:kamus_app/models/update_metadata.dart';

import '../support/test_db.dart';

void main() {
  late Directory tempDir;
  late Directory updateTemp;
  late KamusDatabaseHelper kamusHelper;
  late LocalDatabaseHelper localHelper;
  late KamusDatabaseInstaller installer;
  late AppMetadataRepository appMetadata;

  setUpAll(initTestDatabaseFactory);

  setUp(() {
    tempDir = createTempDir('database_update');
    updateTemp = Directory(p.join(tempDir.path, 'tmp'))
      ..createSync(recursive: true);
    kamusHelper = KamusDatabaseHelper(
      customPath: p.join(tempDir.path, 'kamus.db'),
      databaseFactoryOverride: databaseFactoryFfi,
    );
    localHelper = LocalDatabaseHelper(
      customPath: p.join(tempDir.path, 'local_data.db'),
      databaseFactoryOverride: databaseFactoryFfi,
    );
    installer = KamusDatabaseInstaller(helper: kamusHelper);
    appMetadata = AppMetadataRepository(
      dataSource: LocalDatabaseSource(dbHelper: localHelper),
    );
  });

  tearDown(() async {
    await kamusHelper.close();
    await localHelper.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<List<int>> buildGzip() async {
    final sourcePath = await createSeededKamusDatabase(
      directoryPath: tempDir.path,
      fileName: 'source.db',
    );
    final bytes = await File(sourcePath).readAsBytes();
    return gzip.encode(bytes);
  }

  UpdateMetadata metadataFor(
    List<int> bytes, {
    int releaseVersion = 2,
    int schemaVersion = 1,
    String minAppVersion = '0.1.0',
    String? sha256Override,
    int? sizeOverride,
  }) {
    return UpdateMetadata(
      releaseVersion: releaseVersion,
      schemaVersion: schemaVersion,
      minAppVersion: minAppVersion,
      channel: 'stable',
      releasedAt: DateTime.utc(2026, 1, 1),
      database: DatabaseInfo(
        file: 'database.sqlite.gz',
        url: 'https://example.test/database.sqlite.gz',
        size: sizeOverride ?? bytes.length,
        sha256: sha256Override ?? sha256.convert(bytes).toString(),
      ),
      manifestUrl: 'https://example.test/manifest.json',
    );
  }

  DatabaseUpdateService buildService(
    UpdateMetadata metadata,
    List<int> gzipBytes, {
    List<Uri>? requests,
  }) {
    final client = MockClient((request) async {
      requests?.add(request.url);
      if (request.url.path.endsWith('active.json')) {
        return http.Response(
          jsonEncode(metadata.toJson()),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }
      if (request.url.path.endsWith(metadata.database.file)) {
        return http.Response.bytes(
          gzipBytes,
          200,
          headers: {'content-length': '${gzipBytes.length}'},
        );
      }
      return http.Response('not found', 404);
    });

    return DatabaseUpdateService(
      network: NetworkSource(
        client: client,
        metadataUrl: 'https://example.test/active.json',
      ),
      kamusRepository: KamusRepository(
        dataSource: KamusDatabaseSource(dbHelper: kamusHelper),
      ),
      installer: installer,
      appMetadata: appMetadata,
      temporaryDirectory: () async => updateTemp,
    );
  }

  test('unduh, verifikasi, dan pasang database terbaru', () async {
    final bytes = await buildGzip();
    final metadata = metadataFor(bytes);
    final progress = <DatabaseUpdatePhase>[];

    final outcome = await buildService(metadata, bytes).installLatest(
      currentAppVersion: '0.1.0',
      onProgress: (value) => progress.add(value.phase),
    );

    expect(outcome.success, isTrue);
    expect(outcome.alreadyLatest, isFalse);
    expect(outcome.metadata?.releaseVersion, 2);
    expect(
      progress,
      containsAllInOrder([
        DatabaseUpdatePhase.checking,
        DatabaseUpdatePhase.downloading,
        DatabaseUpdatePhase.verifying,
        DatabaseUpdatePhase.installing,
      ]),
    );

    expect(await installer.checkStatus(), KamusInstallStatus.ready);
    expect(await appMetadata.getDbVersion(), '2');
    expect(await appMetadata.getLastUpdateCheck(), isNotNull);

    final source = KamusDatabaseSource(dbHelper: kamusHelper);
    expect(await source.searchByLemma(query: 'alpha'), hasLength(1));

    final workDir = Directory(p.join(updateTemp.path, 'kamus_update'));
    expect(await workDir.exists(), isFalse);
  });

  test('checksum tidak cocok ditolak tanpa memasang database', () async {
    final bytes = await buildGzip();
    final metadata = metadataFor(bytes, sha256Override: '0' * 64);

    final outcome = await buildService(
      metadata,
      bytes,
    ).installLatest(currentAppVersion: '0.1.0');

    expect(outcome.success, isFalse);
    expect(outcome.error, contains('Checksum'));
    expect(await installer.checkStatus(), KamusInstallStatus.notInstalled);
    expect(await appMetadata.getDbVersion(), isNull);
  });

  test('ukuran file tidak sesuai ditolak sebelum verifikasi', () async {
    final bytes = await buildGzip();
    final metadata = metadataFor(bytes, sizeOverride: bytes.length + 10);

    final outcome = await buildService(
      metadata,
      bytes,
    ).installLatest(currentAppVersion: '0.1.0');

    expect(outcome.success, isFalse);
    expect(outcome.error, contains('Ukuran file'));
    expect(await installer.checkStatus(), KamusInstallStatus.notInstalled);
  });

  test('aplikasi terlalu lama tidak boleh memasang database', () async {
    final bytes = await buildGzip();
    final metadata = metadataFor(bytes, minAppVersion: '0.2.0');
    final requests = <Uri>[];

    final outcome = await buildService(
      metadata,
      bytes,
      requests: requests,
    ).installLatest(currentAppVersion: '0.1.0');

    expect(outcome.success, isFalse);
    expect(outcome.error, contains('terlalu lama'));
    expect(requests, hasLength(1));
  });

  test('skema tidak didukung ditolak', () async {
    final bytes = await buildGzip();
    final metadata = metadataFor(bytes, schemaVersion: 2);

    final outcome = await buildService(
      metadata,
      bytes,
    ).installLatest(currentAppVersion: '0.1.0');

    expect(outcome.success, isFalse);
    expect(outcome.error, contains('skema v2'));
  });

  test('database yang sudah terbaru tidak diunduh ulang', () async {
    final bytes = await buildGzip();
    final gzipFile = File(p.join(tempDir.path, 'seed.sqlite.gz'));
    await gzipFile.writeAsBytes(bytes, flush: true);
    expect((await installer.installFromGzip(gzipFile)).success, isTrue);

    final metadata = metadataFor(bytes, releaseVersion: 1);
    final requests = <Uri>[];

    final outcome = await buildService(
      metadata,
      bytes,
      requests: requests,
    ).installLatest(currentAppVersion: '0.1.0');

    expect(outcome.success, isTrue);
    expect(outcome.alreadyLatest, isTrue);
    expect(requests, hasLength(1));
    expect(await appMetadata.getLastUpdateCheck(), isNotNull);
  });
}
