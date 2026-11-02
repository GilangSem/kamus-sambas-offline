import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/kamus_database_source.dart';
import '../../data/datasources/local_database_source.dart';
import '../../data/local/kamus_database_helper.dart';
import '../../data/local/kamus_database_installer.dart';
import '../../data/local/local_database_helper.dart';
import '../../data/repositories/app_metadata_repository.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/kamus_repository.dart';
import '../../data/repositories/search_history_repository.dart';
import '../../models/category_with_count.dart';
import '../../models/database_status.dart';
import '../../models/search_result.dart';
import '../../models/word.dart';
import '../../models/word_detail.dart';

/// Helper database kamus (artifact rilis).
final kamusHelperProvider = Provider<KamusDatabaseHelper>(
  (ref) => KamusDatabaseHelper.instance,
);

/// Helper database data pengguna (terpisah dari kamus).
final localHelperProvider = Provider<LocalDatabaseHelper>(
  (ref) => LocalDatabaseHelper.instance,
);

final kamusDataSourceProvider = Provider<KamusDatabaseSource>(
  (ref) => KamusDatabaseSource(dbHelper: ref.watch(kamusHelperProvider)),
);

final localDataSourceProvider = Provider<LocalDatabaseSource>(
  (ref) => LocalDatabaseSource(dbHelper: ref.watch(localHelperProvider)),
);

final kamusRepositoryProvider = Provider<KamusRepository>(
  (ref) => KamusRepository(dataSource: ref.watch(kamusDataSourceProvider)),
);

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(dataSource: ref.watch(localDataSourceProvider)),
);

final historyRepositoryProvider = Provider<SearchHistoryRepository>(
  (ref) =>
      SearchHistoryRepository(dataSource: ref.watch(localDataSourceProvider)),
);

final appMetadataRepositoryProvider = Provider<AppMetadataRepository>(
  (ref) =>
      AppMetadataRepository(dataSource: ref.watch(localDataSourceProvider)),
);

final databaseInstallerProvider = Provider<KamusDatabaseInstaller>(
  (ref) => KamusDatabaseInstaller(helper: ref.watch(kamusHelperProvider)),
);

/// Status database kamus beserta ringkasan versi dan jumlah kosakata.
final databaseStatusProvider = FutureProvider<DatabaseStatus>((ref) async {
  final installer = ref.watch(databaseInstallerProvider);
  final helper = ref.watch(kamusHelperProvider);
  final repository = ref.watch(kamusRepositoryProvider);

  final installStatus = await installer.checkStatus();

  if (installStatus == KamusInstallStatus.notInstalled) {
    return DatabaseStatus.notInstalled();
  }

  if (installStatus == KamusInstallStatus.invalid) {
    final validation = await helper.validateSchema();
    return DatabaseStatus.invalid(
      validation.errorMessage ?? 'Database kamus tidak valid.',
    );
  }

  final wordCount = await repository.getWordCount();
  final meta = await repository.getReleaseMeta();

  return DatabaseStatus(
    readiness: DatabaseReadiness.ready,
    wordCount: wordCount,
    releaseVersion: int.tryParse(meta['release_version'] ?? ''),
    schemaVersion: int.tryParse(meta['schema_version'] ?? ''),
    releasedAt: meta['released_at'],
    channel: meta['channel'],
  );
});

/// Kategori beserta jumlah kata. Kosong jika database belum siap.
final categoriesProvider = FutureProvider.autoDispose<List<CategoryWithCount>>((
  ref,
) async {
  final status = await ref.watch(databaseStatusProvider.future);
  if (!status.isReady) return const [];
  return ref.watch(kamusRepositoryProvider).getCategoriesWithCounts();
});

/// Kata harian (deterministik per tanggal).
final dailyWordProvider = FutureProvider.autoDispose<Word?>((ref) async {
  final status = await ref.watch(databaseStatusProvider.future);
  if (!status.isReady) return null;
  return ref.watch(kamusRepositoryProvider).getDailyWord();
});

/// Kata acak; gunakan `ref.invalidate(randomWordProvider)` untuk mengacak lagi.
final randomWordProvider = FutureProvider.autoDispose<Word?>((ref) async {
  final status = await ref.watch(databaseStatusProvider.future);
  if (!status.isReady) return null;
  return ref.watch(kamusRepositoryProvider).getRandomWord();
});

/// Ringkasan (lemma + arti) kata harian untuk beranda.
final dailyWordSummaryProvider = FutureProvider.autoDispose<SearchResult?>((
  ref,
) async {
  final word = await ref.watch(dailyWordProvider.future);
  if (word == null) return null;
  final summaries = await ref
      .watch(kamusRepositoryProvider)
      .getWordSummariesByIds([word.id]);
  return summaries.isEmpty ? null : summaries.first;
});

/// Ringkasan (lemma + arti) kata acak untuk beranda.
final randomWordSummaryProvider = FutureProvider.autoDispose<SearchResult?>((
  ref,
) async {
  final word = await ref.watch(randomWordProvider.future);
  if (word == null) return null;
  final summaries = await ref
      .watch(kamusRepositoryProvider)
      .getWordSummariesByIds([word.id]);
  return summaries.isEmpty ? null : summaries.first;
});

/// Detail kata berdasarkan id.
final wordDetailProvider = FutureProvider.autoDispose
    .family<WordDetail, String>((ref, wordId) {
      return ref.watch(kamusRepositoryProvider).getWordDetail(wordId: wordId);
    });

/// Daftar kata dalam satu kategori.
final categoryWordsProvider = FutureProvider.autoDispose
    .family<List<SearchResult>, String>((ref, categoryId) {
      return ref
          .watch(kamusRepositoryProvider)
          .getWordsByCategory(categoryId: categoryId);
    });
