import '../datasources/local_database_source.dart';
import '../../models/favorite.dart';

/// Repository untuk favorites operations
class FavoritesRepository {
  final LocalDatabaseSource _dataSource;

  FavoritesRepository({LocalDatabaseSource? dataSource})
    : _dataSource = dataSource ?? LocalDatabaseSource();

  Future<void> addFavorite(String wordId) async {
    final favorite = Favorite(
      wordId: wordId,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    await _dataSource.addFavorite(favorite);
  }

  Future<void> removeFavorite(String wordId) =>
      _dataSource.removeFavorite(wordId);

  Future<bool> isFavorite(String wordId) => _dataSource.isFavorite(wordId);

  Future<List<String>> getAllFavoriteWordIds() async {
    final favorites = await _dataSource.getAllFavorites();
    return favorites.map((f) => f.wordId).toList();
  }

  Future<int> getFavoriteCount() => _dataSource.getFavoriteCount();
}
