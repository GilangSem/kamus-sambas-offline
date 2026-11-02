import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kamus_app/data/datasources/kamus_database_source.dart';
import 'package:kamus_app/data/local/kamus_database_helper.dart';
import 'package:kamus_app/data/local/kamus_database_installer.dart';

import '../support/test_db.dart';

void main() {
  late Directory tempDir;
  late String targetPath;
  late KamusDatabaseHelper helper;
  late KamusDatabaseInstaller installer;

  setUpAll(initTestDatabaseFactory);

  setUp(() {
    tempDir = createTempDir('kamus_installer');
    targetPath = p.join(tempDir.path, 'kamus.db');
    helper = KamusDatabaseHelper(
      customPath: targetPath,
      databaseFactoryOverride: databaseFactoryFfi,
    );
    installer = KamusDatabaseInstaller(helper: helper);
  });

  tearDown(() async {
    await helper.close();
    tempDir.deleteSync(recursive: true);
  });

  Future<File> gzipSourceDatabase({String name = 'source.db'}) async {
    final sourcePath = await createSeededKamusDatabase(
      directoryPath: tempDir.path,
      fileName: name,
    );
    final bytes = await File(sourcePath).readAsBytes();
    final gzFile = File(p.join(tempDir.path, '$name.gz'));
    await gzFile.writeAsBytes(gzip.encode(bytes), flush: true);
    return gzFile;
  }

  test('status notInstalled saat belum ada database', () async {
    expect(await installer.checkStatus(), KamusInstallStatus.notInstalled);
  });

  test('instalasi awal dari gzip berhasil dan bisa dicari offline', () async {
    final gzFile = await gzipSourceDatabase();

    final result = await installer.installFromGzip(gzFile);
    expect(result.success, isTrue);
    expect(result.schemaVersion, 1);
    expect(await installer.checkStatus(), KamusInstallStatus.ready);

    final source = KamusDatabaseSource(dbHelper: helper);
    final results = await source.searchByLemma(query: 'alpha');
    expect(results, hasLength(1));
  });

  test('gzip korup gagal tanpa merusak database lama', () async {
    final gzFile = await gzipSourceDatabase();
    await installer.installFromGzip(gzFile);

    final corrupt = File(p.join(tempDir.path, 'corrupt.sqlite.gz'));
    await corrupt.writeAsBytes([1, 2, 3, 4, 5], flush: true);

    final result = await installer.installFromGzip(corrupt);
    expect(result.success, isFalse);
    expect(await installer.checkStatus(), KamusInstallStatus.ready);

    final source = KamusDatabaseSource(dbHelper: helper);
    expect(await source.searchByLemma(query: 'alpha'), hasLength(1));
  });

  test('sqlite di dalam gzip tidak valid ditolak', () async {
    final brokenPath = await createBrokenKamusDatabase(
      directoryPath: tempDir.path,
    );
    final bytes = await File(brokenPath).readAsBytes();
    final gzFile = File(p.join(tempDir.path, 'broken.db.gz'));
    await gzFile.writeAsBytes(gzip.encode(bytes), flush: true);

    final result = await installer.installFromGzip(gzFile);
    expect(result.success, isFalse);
    expect(await installer.checkStatus(), KamusInstallStatus.notInstalled);
  });

  test('database lama tetap utuh jika update dari gzip tidak valid', () async {
    final gzFile = await gzipSourceDatabase();
    await installer.installFromGzip(gzFile);

    final brokenPath = await createBrokenKamusDatabase(
      directoryPath: tempDir.path,
    );
    final brokenBytes = await File(brokenPath).readAsBytes();
    final brokenGz = File(p.join(tempDir.path, 'broken2.db.gz'));
    await brokenGz.writeAsBytes(gzip.encode(brokenBytes), flush: true);

    final result = await installer.installFromGzip(brokenGz);
    expect(result.success, isFalse);

    final source = KamusDatabaseSource(dbHelper: helper);
    expect(await source.searchByLemma(query: 'beta'), hasLength(1));
  });
}
