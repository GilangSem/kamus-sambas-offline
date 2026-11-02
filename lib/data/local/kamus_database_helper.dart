import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite Database helper untuk database kamus (read-only, berasal dari
/// GitHub Release). Data pengguna TIDAK disimpan di sini — lihat
/// [LocalDatabaseHelper].
class KamusDatabaseHelper {
  static const String defaultDbName = 'kamus.db';
  static const int _version = 1;

  // Nama tabel kamus (kontrak schema v1)
  static const String tableReleaseMeta = 'release_meta';
  static const String tableLanguages = 'languages';
  static const String tableDialects = 'dialects';
  static const String tableWordClasses = 'word_classes';
  static const String tableCategories = 'categories';
  static const String tableWords = 'words';
  static const String tableMeanings = 'meanings';
  static const String tableMeaningTranslations = 'meaning_translations';
  static const String tableExamples = 'examples';
  static const String tableWordVariants = 'word_variants';
  static const String tableWordCategories = 'word_categories';
  static const String tableLexicalRelations = 'lexical_relations';
  static const String tablePronunciations = 'pronunciations';
  static const String tableWordImages = 'word_images';
  static const String tableWordAudios = 'word_audios';
  static const String tableWordsFts = 'words_fts';

  /// Path absolut database. Null berarti gunakan `getDatabasesPath()`.
  final String? customPath;

  /// Factory alternatif (dipakai test / platform non-mobile).
  final DatabaseFactory? databaseFactoryOverride;

  Database? _database;

  /// Singleton untuk pemakaian aplikasi normal.
  static final KamusDatabaseHelper instance = KamusDatabaseHelper();

  KamusDatabaseHelper({this.customPath, this.databaseFactoryOverride});

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Path absolut file database kamus yang dipakai saat ini.
  Future<String> resolvePath() async =>
      customPath ?? join(await getDatabasesPath(), defaultDbName);

  Future<Database> _initDatabase() async {
    final factory = databaseFactoryOverride ?? databaseFactory;
    final path = await resolvePath();

    // Database kamus tidak pernah dibuat oleh aplikasi; hanya dipasang dari
    // artifact rilis. Jika belum ada, jangan buat file kosong.
    if (!await File(path).exists()) {
      throw StateError('Database kamus belum terpasang.');
    }

    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
  }

  /// Validasi artifact kamus: integrity, schema_version, tabel terlarang,
  /// dan smoke test FTS5.
  Future<ValidationResult> validateSchema() async {
    try {
      final db = await database;

      final integrityResult = await db.rawQuery('PRAGMA integrity_check');
      final integrityCheck = integrityResult.isNotEmpty
          ? integrityResult.first.values.first?.toString() ?? 'unknown'
          : 'unknown';
      if (integrityCheck != 'ok') {
        return ValidationResult.invalid(
          'Pemeriksaan integritas gagal: $integrityCheck',
        );
      }

      final schemaResult = await db.query(
        tableReleaseMeta,
        where: 'key = ?',
        whereArgs: ['schema_version'],
        limit: 1,
      );
      if (schemaResult.isEmpty) {
        return ValidationResult.invalid(
          'schema_version tidak ditemukan di release_meta',
        );
      }

      final schemaVersion = int.tryParse(
        schemaResult.first['value'].toString(),
      );
      if (schemaVersion == null) {
        return ValidationResult.invalid(
          'schema_version bukan bilangan bulat yang valid',
        );
      }

      const forbiddenTables = <String>[
        'users',
        'auth_identities',
        'refresh_tokens',
        'email_verification_otps',
        'password_reset_tokens',
        'contributions',
        'audit_logs',
        'votes',
        'comments',
        'bookmarks',
        'discussions',
      ];

      final tablesResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      final tableNames = tablesResult.map((r) => r['name'].toString()).toList();

      for (final forbidden in forbiddenTables) {
        if (tableNames.contains(forbidden)) {
          return ValidationResult.invalid(
            'Tabel terlarang ditemukan: $forbidden',
            schemaVersion: schemaVersion,
          );
        }
      }

      try {
        await db.rawQuery('SELECT word_id FROM words_fts LIMIT 1');
      } catch (e) {
        return ValidationResult.invalid(
          'Smoke test FTS5 gagal: $e',
          schemaVersion: schemaVersion,
        );
      }

      return ValidationResult.valid(schemaVersion);
    } catch (e) {
      return ValidationResult.invalid('Validasi schema error: $e');
    }
  }

  /// Apakah database kamus sudah ada dan bisa dibuka.
  Future<bool> exists() async {
    final path = await resolvePath();
    return File(path).exists();
  }

  /// Tutup koneksi database.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Ganti database lama dengan database baru secara aman.
  ///
  /// Urutan: tutup koneksi → backup → salin baru → buka → validasi.
  /// Jika validasi gagal, database lama dipulihkan dari backup.
  Future<void> atomicSwapDatabase({
    required String newDatabasePath,
    required String backupPath,
  }) async {
    final path = await resolvePath();

    final currentFile = File(path);
    final newFile = File(newDatabasePath);
    final backupFile = File(backupPath);

    if (!await newFile.exists()) {
      throw Exception('Database baru tidak ditemukan: $newDatabasePath');
    }

    await close();

    var backedUp = false;
    try {
      if (await currentFile.exists()) {
        await currentFile.copy(backupPath);
        backedUp = true;
      }

      await newFile.copy(path);

      _database = await _initDatabase();
      final validation = await validateSchema();

      if (!validation.isValid) {
        await close();
        if (backedUp && await backupFile.exists()) {
          await currentFile.delete();
          await backupFile.copy(path);
        }
        _database = await _initDatabase();
        throw Exception(
          'Validasi database baru gagal: ${validation.errorMessage}',
        );
      }
    } on FileSystemException catch (e) {
      await close();
      if (backedUp && await backupFile.exists()) {
        await backupFile.copy(path);
        _database = await _initDatabase();
      }
      throw Exception('Operasi file saat ganti database gagal: $e');
    }
  }
}

/// Hasil validasi database kamus.
class ValidationResult {
  final bool isValid;
  final int? schemaVersion;
  final String? errorMessage;

  const ValidationResult._(this.isValid, this.schemaVersion, this.errorMessage);

  factory ValidationResult.valid(int schemaVersion) =>
      ValidationResult._(true, schemaVersion, null);

  factory ValidationResult.invalid(String message, {int? schemaVersion}) =>
      ValidationResult._(false, schemaVersion, message);
}
