import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kamus_app/data/local/kamus_database_helper.dart';
import 'package:kamus_app/data/local/local_database_helper.dart';
import 'package:kamus_app/presentation/pages/word_detail_page.dart';
import 'package:kamus_app/presentation/providers/app_providers.dart';
import 'package:kamus_app/presentation/theme/app_theme.dart';

import '../support/test_db.dart';

void main() {
  late Directory tempDir;
  late KamusDatabaseHelper kamusHelper;
  late LocalDatabaseHelper localHelper;

  setUpAll(initTestDatabaseFactory);

  setUp(() async {
    tempDir = createTempDir('detail_page');
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
  });

  tearDown(() async {
    await kamusHelper.close();
    await localHelper.close();
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        await tempDir.delete(recursive: true);
        break;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        kamusHelperProvider.overrideWithValue(kamusHelper),
        localHelperProvider.overrideWithValue(localHelper),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const WordDetailPage(wordId: 'w-alpha', initialLemma: 'alpha'),
      ),
    );
  }

  Future<void> pumpLoaded(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    for (var attempt = 0; attempt < 40; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
      if (find.text('definisi alpha').evaluate().isNotEmpty) break;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('menampilkan makna, contoh, relasi, dan kategori', (
    tester,
  ) async {
    await pumpLoaded(tester);

    expect(find.text('alpha'), findsWidgets);
    expect(find.text('definisi alpha'), findsOneWidget);
    expect(find.text('glosalpha'), findsOneWidget);
    expect(find.text('kalimat alpha'), findsOneWidget);
    expect(find.text('kalimat terjemahan alpha'), findsOneWidget);
    expect(find.text('Sinonim · beta'), findsOneWidget);
    expect(find.text('Kategori Uji'), findsOneWidget);
    expect(find.text('Variasi Kata'), findsOneWidget);
  });

  testWidgets('aksi favorit menyimpan kata ke database pengguna', (
    tester,
  ) async {
    await pumpLoaded(tester);

    expect(find.byTooltip('Simpan ke favorit'), findsOneWidget);
    await tester.tap(find.byTooltip('Simpan ke favorit'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();

    expect(find.byTooltip('Hapus dari favorit'), findsOneWidget);

    final context = tester.element(find.byType(WordDetailPage));
    final container = ProviderScope.containerOf(context);
    final saved = await tester.runAsync(
      () => container.read(favoritesRepositoryProvider).isFavorite('w-alpha'),
    );
    expect(saved, isTrue);
  });
}
