import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/search_history_repository.dart';
import '../../models/search_history.dart';
import 'app_providers.dart';

class HistoryState {
  final bool isLoading;
  final List<SearchHistory> items;
  final String? error;

  const HistoryState({
    this.isLoading = true,
    this.items = const [],
    this.error,
  });

  HistoryState copyWith({
    bool? isLoading,
    List<SearchHistory>? items,
    String? error,
    bool clearError = false,
  }) {
    return HistoryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Controller riwayat pencarian lokal.
class HistoryController extends StateNotifier<HistoryState> {
  final SearchHistoryRepository _repository;

  HistoryController(this._repository) : super(const HistoryState()) {
    load();
  }

  Future<void> load() async {
    try {
      final items = await _repository.getSearchHistory();
      if (!mounted) return;
      state = HistoryState(isLoading: false, items: items);
    } catch (_) {
      if (!mounted) return;
      state = const HistoryState(
        isLoading: false,
        error: 'Gagal memuat riwayat pencarian.',
      );
    }
  }

  Future<void> remove(int id) async {
    await _repository.deleteSearchHistory(id);
    if (!mounted) return;
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
  }

  Future<void> clearAll() async {
    await _repository.clearAllSearchHistory();
    if (!mounted) return;
    state = state.copyWith(items: const []);
  }
}

final historyControllerProvider =
    StateNotifierProvider<HistoryController, HistoryState>((ref) {
      return HistoryController(ref.watch(historyRepositoryProvider));
    });
