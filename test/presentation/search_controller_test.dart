import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kamus_app/data/local/kamus_database_helper.dart';
import 'package:kamus_app/data/local/local_database_helper.dart';
import 'package:kamus_app/models/database_status.dart';
import 'package:kamus_app/models/favorite.dart';
import 'package:kamus_app/presentation/providers/app_providers.dart';
import 'package:kamus_app/presentation/providers/favorites_controller.dart';
import 'package:kamus_app/presentation/providers/search_controller.dart';

import '../support/test_db.dart';

void main() {
  late Directory tempDir;
  late KamusDatabaseHelper kamusHelper;
  late LocalDatabaseHelper localHelper;
  late ProviderContainer container;

  setUpAll(initTestDatabaseFactory);

  setUp(() async {
    tempDir = createTempDir('search_provider');
    final kamusPath = await createSeededKamusDatabase(
      directoryPath: tempDir.path,
    );
    kamusHelper = KamusDatabaseHelper(
      customPath: kamusPath,
      databaseFactoryOverride: databaseFactoryFfi,
    );
    localHelper = LocalDatabaseHelper(
      customPath: p.join(tempDir.path, 'local_data.db'),
      databaseFactoryOverride: databaseFactoryFfi,
    );

    container = ProviderContainer(
      overrides: [
        kamusHelperProvider.overrideWithValue(kamusHelper),
        localHelperProvider.overrideWithValue(localHelper),
      ],
    );
    container.listen(searchControllerProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await kamusHelper.close();
    await localHelper.close();
    tempDir.deleteSync(recursive: true);
  });

  group('SearchController', () {
    test('mencari lemma Sambas secara offline', () async {
      final controller = container.read(searchControllerProvider.notifier);
      controller.updateQuery('alp');
      await controller.submit();

      final state = container.read(searchControllerProvider);
      expect(state.hasSearched, isTrue);
      expect(state.error, isNull);
      expect(state.results.map((r) => r.word.lemma), contains('alpha'));
    });

    test('mencari arti Bahasa Indonesia', () async {
      final controller = container.read(searchControllerProvider.notifier);
      controller.setMode(SearchMode.indonesia);
      controller.updateQuery('glosalpha');
      await controller.submit();

      final state = container.read(searchControllerProvider);
      expect(state.results.map((r) => r.word.lemma), contains('alpha'));
    });

    test('kata draft tidak muncul pada hasil pencarian', () async {
      final controller = container.read(searchControllerProvider.notifier);
      controller.updateQuery('gamma');
      await controller.submit();

      expect(container.read(searchControllerProvider).results, isEmpty);
    });

    test('query yang dikirim berulang tidak menduplikasi riwayat', () async {
      final controller = container.read(searchControllerProvider.notifier);
      controller.updateQuery('alpha');
      await controller.submit();
      await controller.submit();

      final history = await container
          .read(historyRepositoryProvider)
          .getSearchHistory();
      expect(history.where((item) => item.query == 'alpha'), hasLength(1));
    });

    test('riwayat menyimpan jumlah hasil terakhir', () async {
      final controller = container.read(searchControllerProvider.notifier);
      controller.updateQuery('alpha');
      await controller.submit();

      final history = await container
          .read(historyRepositoryProvider)
          .getSearchHistory();
      expect(history.single.resultCount, 1);
    });
  });

  group('Provider katalog', () {
    test('status database siap beserta metadata rilis', () async {
      final status = await container.read(databaseStatusProvider.future);

      expect(status.readiness, DatabaseReadiness.ready);
      expect(status.wordCount, 2);
      expect(status.releaseVersion, 1);
      expect(status.schemaVersion, 1);
    });

    test('kategori memuat jumlah kata published', () async {
      final categories = await container.read(categoriesProvider.future);
      expect(categories, hasLength(1));
      expect(categories.first.category.name, 'Kategori Uji');
      expect(categories.first.wordCount, 1);
    });

    test('kata harian & acak hanya dari kata published', () async {
      final daily = await container.read(dailyWordProvider.future);
      final random = await container.read(randomWordProvider.future);

      expect(daily, isNotNull);
      expect(random, isNotNull);
      expect(['alpha', 'beta'], contains(daily!.lemma));
      expect(['alpha', 'beta'], contains(random!.lemma));
    });

    test('detail kata melalui provider', () async {
      final detail = await container.read(wordDetailProvider('w-alpha').future);
      expect(detail.word.lemma, 'alpha');
      expect(detail.meanings, hasLength(1));
      expect(detail.relations.first.targetWord.id, 'w-beta');
    });

    test('ringkasan favorit mengikuti urutan favorit', () async {
      final localSource = container.read(localDataSourceProvider);
      await localSource.addFavorite(Favorite(wordId: 'w-beta', createdAt: 100));
      await localSource.addFavorite(
        Favorite(wordId: 'w-alpha', createdAt: 200),
      );
      await container.read(favoritesControllerProvider.notifier).refresh();

      final favorites = await container.read(favoriteWordsProvider.future);
      expect(favorites.map((r) => r.word.id).toList(), ['w-alpha', 'w-beta']);
    });
  });
}
