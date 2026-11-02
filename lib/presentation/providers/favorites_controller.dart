import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/favorites_repository.dart';
import '../../models/search_result.dart';
import 'app_providers.dart';

class FavoritesState {
  final bool isLoading;
  final List<String> wordIds;

  const FavoritesState({this.isLoading = true, this.wordIds = const []});

  bool isFavorite(String wordId) => wordIds.contains(wordId);
  int get count => wordIds.length;

  FavoritesState copyWith({bool? isLoading, List<String>? wordIds}) {
    return FavoritesState(
      isLoading: isLoading ?? this.isLoading,
      wordIds: wordIds ?? this.wordIds,
    );
  }
}

/// Controller favorit. Data tersimpan di database pengguna (terpisah dari
/// database kamus) sehingga tidak hilang saat kamus diperbarui.
class FavoritesController extends StateNotifier<FavoritesState> {
  final FavoritesRepository _repository;

  FavoritesController(this._repository) : super(const FavoritesState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final ids = await _repository.getAllFavoriteWordIds();
      if (!mounted) return;
      state = FavoritesState(isLoading: false, wordIds: ids);
    } catch (_) {
      if (!mounted) return;
      state = const FavoritesState(isLoading: false);
    }
  }

  Future<void> refresh() => _load();

  /// Toggle favorit. Mengembalikan status favorit setelah perubahan.
  Future<bool> toggle(String wordId) async {
    final wasFavorite = state.isFavorite(wordId);
    if (wasFavorite) {
      await _repository.removeFavorite(wordId);
    } else {
      await _repository.addFavorite(wordId);
    }

    if (!mounted) return !wasFavorite;
    final next = List<String>.from(state.wordIds);
    if (wasFavorite) {
      next.remove(wordId);
    } else {
      next.insert(0, wordId);
    }
    state = state.copyWith(wordIds: next);
    return !wasFavorite;
  }
}

final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, FavoritesState>((ref) {
      return FavoritesController(ref.watch(favoritesRepositoryProvider));
    });

/// Ringkasan kata favorit (lemma + arti) sesuai urutan favorit terbaru.
final favoriteWordsProvider = FutureProvider.autoDispose<List<SearchResult>>((
  ref,
) async {
  final favorites = ref.watch(favoritesControllerProvider);
  if (favorites.isLoading || favorites.wordIds.isEmpty) return const [];
  return ref
      .watch(kamusRepositoryProvider)
      .getWordSummariesByIds(favorites.wordIds);
});
