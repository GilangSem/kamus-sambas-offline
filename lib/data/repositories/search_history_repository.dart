import '../datasources/local_database_source.dart';
import '../../models/search_history.dart';

/// Repository untuk search history operations
class SearchHistoryRepository {
  final LocalDatabaseSource _dataSource;

  SearchHistoryRepository({LocalDatabaseSource? dataSource})
    : _dataSource = dataSource ?? LocalDatabaseSource();

  Future<void> addSearchHistory({
    required String query,
    int resultCount = 0,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    // Satu query hanya muncul sekali (entri terbaru menggantikan yang lama).
    await _dataSource.deleteSearchHistoryByQuery(normalized);

    final history = SearchHistory(
      query: normalized,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      resultCount: resultCount,
    );
    await _dataSource.addSearchHistory(history);
  }

  Future<List<SearchHistory>> getSearchHistory({
    int limit = 50,
    int offset = 0,
  }) => _dataSource.getSearchHistory(limit: limit, offset: offset);

  Future<void> deleteSearchHistory(int id) =>
      _dataSource.deleteSearchHistory(id);

  Future<void> clearAllSearchHistory() => _dataSource.clearAllSearchHistory();
}
