import 'package:sqflite/sqflite.dart';
import '../../models/favorite.dart';
import '../../models/search_history.dart';
import '../../models/app_meta.dart';
import '../local/local_database_helper.dart';

/// Data source untuk local user data (favorites, search history)
class LocalDatabaseSource {
  final LocalDatabaseHelper _dbHelper;

  LocalDatabaseSource({LocalDatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? LocalDatabaseHelper.instance;

  /// Favorites operations
  Future<void> addFavorite(Favorite favorite) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        LocalDatabaseHelper.tableFavorites,
        favorite.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  Future<void> removeFavorite(String wordId) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        LocalDatabaseHelper.tableFavorites,
        where: 'word_id = ?',
        whereArgs: [wordId],
      );
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }

  Future<bool> isFavorite(String wordId) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        LocalDatabaseHelper.tableFavorites,
        where: 'word_id = ?',
        whereArgs: [wordId],
        limit: 1,
      );
      return results.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check favorite: $e');
    }
  }

  Future<List<Favorite>> getAllFavorites() async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        LocalDatabaseHelper.tableFavorites,
        orderBy: 'created_at DESC',
      );
      return results.map((r) => Favorite.fromJson(r)).toList();
    } catch (e) {
      throw Exception('Failed to get favorites: $e');
    }
  }

  Future<int> getFavoriteCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${LocalDatabaseHelper.tableFavorites}',
      );
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      throw Exception('Failed to get favorite count: $e');
    }
  }

  /// Search history operations
  Future<void> addSearchHistory(SearchHistory history) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        LocalDatabaseHelper.tableSearchHistory,
        history.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to add search history: $e');
    }
  }

  Future<List<SearchHistory>> getSearchHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        LocalDatabaseHelper.tableSearchHistory,
        orderBy: 'timestamp DESC',
        limit: limit,
        offset: offset,
      );
      return results.map((r) => SearchHistory.fromJson(r)).toList();
    } catch (e) {
      throw Exception('Failed to get search history: $e');
    }
  }

  Future<void> deleteSearchHistory(int id) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        LocalDatabaseHelper.tableSearchHistory,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete search history: $e');
    }
  }

  Future<void> clearAllSearchHistory() async {
    try {
      final db = await _dbHelper.database;
      await db.delete(LocalDatabaseHelper.tableSearchHistory);
    } catch (e) {
      throw Exception('Failed to clear search history: $e');
    }
  }

  /// Hapus entri riwayat dengan query yang sama (untuk deduplikasi).
  Future<void> deleteSearchHistoryByQuery(String query) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        LocalDatabaseHelper.tableSearchHistory,
        where: 'query = ?',
        whereArgs: [query],
      );
    } catch (e) {
      throw Exception('Failed to delete search history by query: $e');
    }
  }

  /// App metadata operations
  Future<void> setAppMeta(AppMeta meta) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        LocalDatabaseHelper.tableAppMeta,
        meta.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to set app meta: $e');
    }
  }

  Future<String?> getAppMeta(String key) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        LocalDatabaseHelper.tableAppMeta,
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (results.isEmpty) return null;
      return results.first['value'] as String;
    } catch (e) {
      throw Exception('Failed to get app meta: $e');
    }
  }

  Future<void> deleteAppMeta(String key) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        LocalDatabaseHelper.tableAppMeta,
        where: 'key = ?',
        whereArgs: [key],
      );
    } catch (e) {
      throw Exception('Failed to delete app meta: $e');
    }
  }
}
