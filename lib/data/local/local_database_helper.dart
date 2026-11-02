import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Database helper untuk data lokal pengguna (favorit, riwayat pencarian,
/// metadata aplikasi). Terpisah dari database kamus agar data pengguna
/// tidak hilang saat database kamus diperbarui.
class LocalDatabaseHelper {
  static const String defaultDbName = 'local_data.db';
  static const int _version = 1;

  static const String tableAppMeta = 'app_meta';
  static const String tableFavorites = 'favorites';
  static const String tableSearchHistory = 'search_history';

  /// Path absolut database. Null berarti gunakan `getDatabasesPath()`.
  final String? customPath;

  /// Factory alternatif (dipakai test / platform non-mobile).
  final DatabaseFactory? databaseFactoryOverride;

  Database? _database;

  /// Singleton untuk pemakaian aplikasi normal.
  static final LocalDatabaseHelper instance = LocalDatabaseHelper();

  LocalDatabaseHelper({this.customPath, this.databaseFactoryOverride});

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final factory = databaseFactoryOverride ?? databaseFactory;
    final path = customPath ?? join(await getDatabasesPath(), defaultDbName);

    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: (db, version) => _createTables(db),
        onUpgrade: (db, oldVersion, newVersion) async {
          // Migrasi lokal di masa depan ditambahkan di sini.
        },
      ),
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $tableAppMeta (
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableFavorites (
        word_id TEXT PRIMARY KEY NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableSearchHistory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        result_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_search_history_timestamp '
      'ON $tableSearchHistory(timestamp DESC)',
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Hapus seluruh data pengguna.
  Future<void> resetAllData() async {
    final db = await database;
    await db.delete(tableFavorites);
    await db.delete(tableSearchHistory);
  }
}
