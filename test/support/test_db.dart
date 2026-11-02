import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// DDL identik dengan kontrak publik `schema/v1.md`.
/// Disalin sebagai konstanta agar test tidak bergantung pada repo TypeScript.
const String publicSchemaDdl = '''
PRAGMA foreign_keys = ON;

CREATE TABLE release_meta (
  key TEXT PRIMARY KEY NOT NULL,
  value TEXT NOT NULL
);

CREATE TABLE languages (
  id TEXT PRIMARY KEY NOT NULL,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  native_name TEXT,
  description TEXT,
  is_active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE dialects (
  id TEXT PRIMARY KEY NOT NULL,
  language_id TEXT NOT NULL REFERENCES languages(id),
  code TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  is_default INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE word_classes (
  id TEXT PRIMARY KEY NOT NULL,
  parent_id TEXT,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  alias TEXT,
  description TEXT
);

CREATE TABLE categories (
  id TEXT PRIMARY KEY NOT NULL,
  parent_id TEXT,
  name TEXT NOT NULL,
  description TEXT
);

CREATE TABLE words (
  id TEXT PRIMARY KEY NOT NULL,
  language_id TEXT NOT NULL REFERENCES languages(id),
  lemma TEXT NOT NULL,
  notes TEXT,
  word_type TEXT NOT NULL DEFAULT 'word',
  usage_labels TEXT NOT NULL DEFAULT '[]',
  status TEXT NOT NULL,
  is_verified INTEGER NOT NULL DEFAULT 0,
  verified_at INTEGER,
  is_corrected INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER
);

CREATE INDEX words_lemma_az_idx ON words (lower(lemma), id);
CREATE INDEX words_language_lemma_idx ON words (language_id, lemma);

CREATE TABLE meanings (
  id TEXT PRIMARY KEY NOT NULL,
  word_id TEXT NOT NULL REFERENCES words(id),
  word_class_id TEXT REFERENCES word_classes(id),
  inherited_from_meaning_id TEXT,
  definition TEXT NOT NULL,
  is_have_definition INTEGER NOT NULL DEFAULT 1,
  is_have_translation INTEGER NOT NULL DEFAULT 1,
  meaning_source TEXT NOT NULL DEFAULT 'manual',
  order_index INTEGER NOT NULL DEFAULT 0,
  notes TEXT,
  status TEXT NOT NULL,
  is_verified INTEGER NOT NULL DEFAULT 0,
  is_corrected INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX meanings_word_order_idx ON meanings (word_id, order_index);

CREATE TABLE meaning_translations (
  id TEXT PRIMARY KEY NOT NULL,
  meaning_id TEXT NOT NULL REFERENCES meanings(id),
  language_id TEXT NOT NULL REFERENCES languages(id),
  translation_text TEXT NOT NULL,
  translation_type TEXT NOT NULL DEFAULT 'direct',
  notes TEXT
);

CREATE TABLE examples (
  id TEXT PRIMARY KEY NOT NULL,
  meaning_id TEXT NOT NULL REFERENCES meanings(id),
  source_language_id TEXT NOT NULL REFERENCES languages(id),
  source_sentence TEXT NOT NULL,
  target_language_id TEXT REFERENCES languages(id),
  target_sentence TEXT,
  source_type TEXT,
  source_reference TEXT,
  notes TEXT,
  status TEXT NOT NULL,
  is_verified INTEGER NOT NULL DEFAULT 0,
  is_corrected INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE word_variants (
  id TEXT PRIMARY KEY NOT NULL,
  word_id TEXT NOT NULL REFERENCES words(id),
  form TEXT NOT NULL,
  variant_type TEXT NOT NULL DEFAULT 'alternative',
  affix_type TEXT,
  affix_value TEXT,
  dialect_id TEXT REFERENCES dialects(id),
  notes TEXT
);

CREATE INDEX word_variants_word_idx ON word_variants (word_id);

CREATE TABLE word_categories (
  word_id TEXT NOT NULL REFERENCES words(id),
  category_id TEXT NOT NULL REFERENCES categories(id),
  PRIMARY KEY (word_id, category_id)
);

CREATE TABLE lexical_relations (
  id TEXT PRIMARY KEY NOT NULL,
  source_word_id TEXT NOT NULL REFERENCES words(id),
  target_word_id TEXT NOT NULL REFERENCES words(id),
  relation_type TEXT NOT NULL,
  notes TEXT,
  status TEXT NOT NULL,
  is_verified INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX lexical_relations_target_idx ON lexical_relations (target_word_id);

CREATE TABLE pronunciations (
  id TEXT PRIMARY KEY NOT NULL,
  word_id TEXT NOT NULL REFERENCES words(id),
  dialect_id TEXT REFERENCES dialects(id),
  notation TEXT NOT NULL DEFAULT 'ipa',
  value TEXT NOT NULL,
  audio_url TEXT,
  speaker_name TEXT,
  notes TEXT,
  status TEXT NOT NULL,
  is_verified INTEGER NOT NULL DEFAULT 0,
  is_corrected INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE word_images (
  id TEXT PRIMARY KEY NOT NULL,
  word_id TEXT NOT NULL REFERENCES words(id),
  url TEXT NOT NULL,
  alt_text TEXT,
  is_primary INTEGER NOT NULL DEFAULT 0,
  content_warnings TEXT NOT NULL DEFAULT '[]',
  attribution TEXT,
  status TEXT NOT NULL,
  is_verified INTEGER NOT NULL DEFAULT 0,
  is_corrected INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX word_images_word_idx ON word_images (word_id);

CREATE TABLE word_audios (
  id TEXT PRIMARY KEY NOT NULL,
  word_id TEXT NOT NULL REFERENCES words(id),
  example_id TEXT REFERENCES examples(id),
  dialect_id TEXT REFERENCES dialects(id),
  url TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  duration_ms INTEGER,
  speaker_name TEXT,
  is_primary INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL,
  is_verified INTEGER NOT NULL DEFAULT 0,
  is_corrected INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX word_audios_word_idx ON word_audios (word_id);
CREATE INDEX word_audios_example_idx ON word_audios (example_id);

CREATE VIRTUAL TABLE words_fts USING fts5(
  word_id UNINDEXED,
  lemma,
  variants,
  translations,
  tokenize = 'unicode61'
);
''';

/// Inisialisasi FFI sekali untuk seluruh test.
void initTestDatabaseFactory() {
  sqfliteFfiInit();
}

/// Buat direktori temporer unik untuk test.
Directory createTempDir(String prefix) =>
    Directory.systemTemp.createTempSync('kamus_$prefix');

/// Membuat database kamus valid berisi fixture UJI (bukan data kamus asli).
///
/// Fixture sengaja memakai token "alpha"/"beta" agar jelas bukan kosakata
/// produksi.
Future<String> createSeededKamusDatabase({
  required String directoryPath,
  String fileName = 'kamus.db',
}) async {
  final path = p.join(directoryPath, fileName);
  final db = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('PRAGMA foreign_keys = ON');
        for (final statement in _splitSql(publicSchemaDdl)) {
          await db.execute(statement);
        }
        await _seedFixtures(db);
      },
    ),
  );
  await db.close();
  return path;
}

/// Membuat database kamus yang sengaja rusak / tidak valid.
Future<String> createBrokenKamusDatabase({
  required String directoryPath,
  String fileName = 'broken.db',
}) async {
  final path = p.join(directoryPath, fileName);
  final db = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE words (id TEXT PRIMARY KEY NOT NULL)');
      },
    ),
  );
  await db.close();
  return path;
}

Future<void> _seedFixtures(Database db) async {
  const now = 1700000000;

  await db.insert('release_meta', {'key': 'release_version', 'value': '1'});
  await db.insert('release_meta', {'key': 'schema_version', 'value': '1'});
  await db.insert('release_meta', {
    'key': 'released_at',
    'value': '2026-01-01T00:00:00.000Z',
  });

  await db.insert('languages', {
    'id': 'lang-sbs',
    'code': 'sbs',
    'name': 'Bahasa Sambas',
    'is_active': 1,
  });
  await db.insert('languages', {
    'id': 'lang-id',
    'code': 'id',
    'name': 'Bahasa Indonesia',
    'is_active': 1,
  });

  await db.insert('word_classes', {
    'id': 'wc-n',
    'code': 'n',
    'name': 'Nomina',
  });

  await db.insert('categories', {'id': 'cat-uji', 'name': 'Kategori Uji'});

  await db.insert('words', {
    'id': 'w-alpha',
    'language_id': 'lang-sbs',
    'lemma': 'alpha',
    'status': 'published',
    'created_at': now,
  });
  await db.insert('words', {
    'id': 'w-beta',
    'language_id': 'lang-sbs',
    'lemma': 'beta',
    'status': 'published',
    'created_at': now,
  });
  await db.insert('words', {
    'id': 'w-draft',
    'language_id': 'lang-sbs',
    'lemma': 'gamma',
    'status': 'draft',
    'created_at': now,
  });

  await db.insert('meanings', {
    'id': 'm-alpha',
    'word_id': 'w-alpha',
    'word_class_id': 'wc-n',
    'definition': 'definisi alpha',
    'status': 'published',
    'order_index': 0,
  });
  await db.insert('meanings', {
    'id': 'm-beta',
    'word_id': 'w-beta',
    'definition': 'definisi beta',
    'status': 'published',
    'order_index': 0,
  });

  await db.insert('meaning_translations', {
    'id': 't-alpha',
    'meaning_id': 'm-alpha',
    'language_id': 'lang-id',
    'translation_text': 'glosalpha',
  });
  await db.insert('meaning_translations', {
    'id': 't-beta',
    'meaning_id': 'm-beta',
    'language_id': 'lang-id',
    'translation_text': 'glosbeta',
  });

  await db.insert('examples', {
    'id': 'e-alpha',
    'meaning_id': 'm-alpha',
    'source_language_id': 'lang-sbs',
    'source_sentence': 'kalimat alpha',
    'target_language_id': 'lang-id',
    'target_sentence': 'kalimat terjemahan alpha',
    'status': 'published',
  });

  await db.insert('word_variants', {
    'id': 'v-alpha',
    'word_id': 'w-alpha',
    'form': 'alfabet',
    'variant_type': 'alternative',
  });

  await db.insert('word_categories', {
    'word_id': 'w-alpha',
    'category_id': 'cat-uji',
  });

  await db.insert('lexical_relations', {
    'id': 'lr-alpha',
    'source_word_id': 'w-alpha',
    'target_word_id': 'w-beta',
    'relation_type': 'synonym',
    'status': 'published',
  });

  await db.insert('word_images', {
    'id': 'img-alpha',
    'word_id': 'w-alpha',
    'url': 'https://example.com/fixture.png',
    'is_primary': 1,
    'status': 'published',
  });

  await db.insert('word_audios', {
    'id': 'au-alpha',
    'word_id': 'w-alpha',
    'url': 'https://example.com/fixture.mp3',
    'mime_type': 'audio/mpeg',
    'file_size': 1000,
    'is_primary': 1,
    'status': 'published',
  });

  await db.insert('words_fts', {
    'word_id': 'w-alpha',
    'lemma': 'alpha',
    'variants': 'alfabet',
    'translations': 'glosalpha',
  });
  await db.insert('words_fts', {
    'word_id': 'w-beta',
    'lemma': 'beta',
    'variants': '',
    'translations': 'glosbeta',
  });
  await db.insert('words_fts', {
    'word_id': 'w-draft',
    'lemma': 'gamma',
    'variants': '',
    'translations': '',
  });
}

/// Memecah script DDL menjadi statement per titik koma.
List<String> _splitSql(String sql) {
  return sql
      .split(';')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
