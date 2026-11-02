import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/kamus_repository.dart';
import '../../data/repositories/search_history_repository.dart';
import '../../models/search_result.dart';
import 'app_providers.dart';

/// Mode pencarian: lemma Sambas atau arti Bahasa Indonesia.
enum SearchMode { sambas, indonesia }

class SearchState {
  final String query;
  final SearchMode mode;
  final bool isLoading;
  final bool hasSearched;
  final List<SearchResult> results;
  final String? error;

  const SearchState({
    this.query = '',
    this.mode = SearchMode.sambas,
    this.isLoading = false,
    this.hasSearched = false,
    this.results = const [],
    this.error,
  });

  SearchState copyWith({
    String? query,
    SearchMode? mode,
    bool? isLoading,
    bool? hasSearched,
    List<SearchResult>? results,
    String? error,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      mode: mode ?? this.mode,
      isLoading: isLoading ?? this.isLoading,
      hasSearched: hasSearched ?? this.hasSearched,
      results: results ?? this.results,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isEmptyQuery => query.trim().isEmpty;
}

/// Controller pencarian dengan debounce dan proteksi race condition.
class SearchController extends StateNotifier<SearchState> {
  final KamusRepository _repository;
  final SearchHistoryRepository _history;

  Timer? _debounce;
  int _requestId = 0;

  SearchController(this._repository, this._history)
    : super(const SearchState());

  void updateQuery(String value) {
    state = state.copyWith(query: value, clearError: true);
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      _requestId++;
      state = state.copyWith(
        results: const [],
        isLoading: false,
        hasSearched: false,
      );
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _run(recordHistory: false);
    });
  }

  void setMode(SearchMode mode) {
    if (state.mode == mode) return;
    state = state.copyWith(mode: mode);
    if (!state.isEmptyQuery) {
      _run(recordHistory: false);
    }
  }

  /// Jalankan pencarian segera dan simpan ke riwayat.
  Future<void> submit() async {
    _debounce?.cancel();
    await _run(recordHistory: true);
  }

  /// Simpan query yang sedang tampil ke riwayat (mis. saat hasil dibuka).
  Future<void> rememberQuery() async {
    final query = state.query.trim();
    if (query.isEmpty) return;
    try {
      await _history.addSearchHistory(
        query: query,
        resultCount: state.results.length,
      );
    } catch (_) {
      // Riwayat bersifat non-kritis; kegagalan tidak mengganggu pencarian.
    }
  }

  void clear() {
    _debounce?.cancel();
    _requestId++;
    state = SearchState(mode: state.mode);
  }

  Future<void> _run({required bool recordHistory}) async {
    final query = state.query.trim();
    if (query.isEmpty) return;

    final requestId = ++_requestId;
    final mode = state.mode;
    state = state.copyWith(
      isLoading: true,
      hasSearched: true,
      clearError: true,
    );

    try {
      final results = mode == SearchMode.sambas
          ? await _repository.searchByLemma(query: query)
          : await _repository.searchByTranslation(query: query);

      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(isLoading: false, results: results);

      if (recordHistory) {
        await _history.addSearchHistory(
          query: query,
          resultCount: results.length,
        );
      }
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Pencarian gagal. Silakan coba lagi.',
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final searchControllerProvider =
    StateNotifierProvider.autoDispose<SearchController, SearchState>((ref) {
      return SearchController(
        ref.watch(kamusRepositoryProvider),
        ref.watch(historyRepositoryProvider),
      );
    });
