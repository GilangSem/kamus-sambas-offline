import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/example.dart';
import '../../models/meaning_translation.dart';
import '../../models/word_detail.dart';
import '../providers/app_providers.dart';
import '../providers/favorites_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/loading_state.dart';
import '../widgets/section_title.dart';
import 'category_words_page.dart';

class WordDetailPage extends ConsumerWidget {
  final String wordId;
  final String? initialLemma;

  const WordDetailPage({super.key, required this.wordId, this.initialLemma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(wordDetailProvider(wordId));

    return Scaffold(
      appBar: AppBar(
        title: Text(initialLemma ?? 'Detail Kata'),
        actions: [_DetailActions(wordId: wordId)],
      ),
      body: detail.when(
        loading: () => const LoadingState(message: 'Memuat detail kata...'),
        error: (_, _) => ErrorState(
          message: 'Detail kata tidak dapat dimuat.',
          onRetry: () => ref.invalidate(wordDetailProvider(wordId)),
        ),
        data: (data) => _DetailBody(detail: data),
      ),
    );
  }
}

class _DetailActions extends ConsumerWidget {
  final String wordId;

  const _DetailActions({required this.wordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(wordDetailProvider(wordId));
    final favorites = ref.watch(favoritesControllerProvider);
    final isFavorite = favorites.isFavorite(wordId);
    final data = detail.valueOrNull;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: isFavorite ? 'Hapus dari favorit' : 'Simpan ke favorit',
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? AppColors.danger : null,
          ),
          onPressed: () async {
            final added = await ref
                .read(favoritesControllerProvider.notifier)
                .toggle(wordId);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  added ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit',
                ),
              ),
            );
          },
        ),
        if (data != null)
          IconButton(
            tooltip: 'Salin',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: _buildShareText(data)),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kata disalin ke papan klip')),
              );
            },
          ),
        if (data != null)
          IconButton(
            tooltip: 'Bagikan',
            icon: const Icon(Icons.share_rounded),
            onPressed: () => Share.share(_buildShareText(data)),
          ),
      ],
    );
  }
}

String _buildShareText(WordDetail detail) {
  final buffer = StringBuffer(detail.word.lemma);

  final pronunciations = detail.pronunciations
      .map((p) => p.value)
      .where((v) => v.trim().isNotEmpty)
      .toList();
  if (pronunciations.isNotEmpty) {
    buffer.writeln('\n[${pronunciations.join(' · ')}]');
  }

  if (detail.meanings.isNotEmpty) {
    buffer.writeln('\nMakna:');
    for (var i = 0; i < detail.meanings.length; i++) {
      final meaning = detail.meanings[i];
      final translations = meaning.translations
          .map((t) => t.translationText)
          .join('; ');
      buffer.write('${i + 1}. ${meaning.meaning.definition}');
      if (translations.isNotEmpty) buffer.write(' ($translations)');
      buffer.writeln();
      for (final example in meaning.examples) {
        buffer.writeln('   "${example.sourceSentence}"');
        if (example.targetSentence != null &&
            example.targetSentence!.trim().isNotEmpty) {
          buffer.writeln('   → ${example.targetSentence}');
        }
      }
    }
  }

  buffer.writeln('\n— Kamus Bahasa Sambas');
  return buffer.toString().trim();
}

class _DetailBody extends StatelessWidget {
  final WordDetail detail;

  const _DetailBody({required this.detail});

  @override
  Widget build(BuildContext context) {
    final word = detail.word;
    final pronunciationText = detail.pronunciations
        .map((p) => p.value)
        .where((v) => v.trim().isNotEmpty)
        .toList();

    final audioUrl = _resolveAudioUrl(detail);

    final usageLabels = word.usageLabels
        .where((label) => label.trim().isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _HeaderCard(
          lemma: word.lemma,
          wordType: word.wordType,
          usageLabels: usageLabels,
          pronunciation: pronunciationText.isEmpty
              ? null
              : pronunciationText.join(' · '),
          audioUrl: audioUrl,
        ),
        if (detail.meanings.isEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Makna belum tersedia untuk kata ini.',
            style: TextStyle(color: AppColors.muted),
          ),
        ] else ...[
          const SizedBox(height: 26),
          SectionTitle(
            title: 'Makna',
            subtitle: detail.meanings.length > 1
                ? '${detail.meanings.length} makna'
                : null,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < detail.meanings.length; i++) ...[
            _MeaningCard(index: i + 1, meaning: detail.meanings[i]),
            if (i != detail.meanings.length - 1) const SizedBox(height: 12),
          ],
        ],
        if (word.notes != null && word.notes!.trim().isNotEmpty) ...[
          const SizedBox(height: 26),
          const SectionTitle(title: 'Catatan'),
          const SizedBox(height: 8),
          _SurfaceBox(child: Text(word.notes!)),
        ],
        if (detail.variants.isNotEmpty) ...[
          const SizedBox(height: 26),
          const SectionTitle(title: 'Variasi Kata'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: detail.variants
                .map(
                  (variant) => Chip(
                    label: Text(
                      '${variant.form} · ${variantTypeLabel(variant.variantType)}',
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        if (detail.relations.isNotEmpty) ...[
          const SizedBox(height: 26),
          const SectionTitle(title: 'Hubungan Kata'),
          const SizedBox(height: 10),
          _RelationList(relations: detail.relations),
        ],
        if (detail.categories.isNotEmpty) ...[
          const SizedBox(height: 26),
          const SectionTitle(title: 'Kategori'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: detail.categories
                .map(
                  (category) => ActionChip(
                    label: Text(category.name),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CategoryWordsPage(
                          categoryId: category.id,
                          categoryName: category.name,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        if (detail.images.isNotEmpty) ...[
          const SizedBox(height: 26),
          const SectionTitle(title: 'Gambar'),
          const SizedBox(height: 10),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: detail.images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final image = detail.images[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    image.url,
                    width: 220,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 220,
                      height: 160,
                      color: AppColors.surface,
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.muted,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Gambar tidak tersedia',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (detail.audios.isNotEmpty) ...[
          const SizedBox(height: 26),
          const SectionTitle(
            title: 'Audio',
            subtitle: 'Membutuhkan koneksi internet',
          ),
          const SizedBox(height: 10),
          for (final audio in detail.audios)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                onPressed: () => _openAudio(context, audio.url),
                icon: const Icon(Icons.volume_up_rounded, size: 19),
                label: Text(
                  audio.speakerName != null
                      ? 'Dengarkan · ${audio.speakerName}'
                      : 'Dengarkan pelafalan',
                ),
              ),
            ),
        ],
      ],
    );
  }

  String? _resolveAudioUrl(WordDetail detail) {
    for (final pronunciation in detail.pronunciations) {
      final url = pronunciation.audioUrl;
      if (url != null && url.trim().isNotEmpty) return url;
    }
    if (detail.audios.isNotEmpty) return detail.audios.first.url;
    return null;
  }

  static Future<void> _openAudio(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan audio tidak valid.')),
      );
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka audio.')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio membutuhkan koneksi internet.')),
      );
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final String lemma;
  final String wordType;
  final List<String> usageLabels;
  final String? pronunciation;
  final String? audioUrl;

  const _HeaderCard({
    required this.lemma,
    required this.wordType,
    required this.usageLabels,
    required this.pronunciation,
    required this.audioUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lemma,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          if (pronunciation != null) ...[
            const SizedBox(height: 4),
            Text(
              pronunciation!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _headerChip(wordTypeLabel(wordType)),
              for (final label in usageLabels)
                _headerChip(usageLabelText(label)),
              if (audioUrl != null)
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _DetailBody._openAudio(context, audioUrl!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.volume_up_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Dengarkan',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MeaningCard extends StatelessWidget {
  final int index;
  final MeaningWithTranslations meaning;

  const _MeaningCard({required this.index, required this.meaning});

  @override
  Widget build(BuildContext context) {
    final definition = meaning.meaning.definition;
    final translations = meaning.translations
        .where((t) => t.translationText.trim().isNotEmpty)
        .toList();
    final notes = meaning.meaning.notes;
    final source = meaning.meaning.meaningSource;

    return _SurfaceBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  definition,
                  style: const TextStyle(
                    fontSize: 15.5,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (meaning.wordClass != null || _sourceLabel(source) != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (meaning.wordClass != null)
                  _Tag(text: meaning.wordClass!.name),
                if (_sourceLabel(source) != null)
                  _Tag(text: _sourceLabel(source)!, subtle: true),
              ],
            ),
          ],
          if (translations.isNotEmpty) ...[
            const SizedBox(height: 12),
            _TranslationList(translations: translations),
          ],
          if (notes != null && notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              notes,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
          if (meaning.examples.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (var i = 0; i < meaning.examples.length; i++) ...[
              _ExampleBlock(example: meaning.examples[i]),
              if (i != meaning.examples.length - 1) const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }

  String? _sourceLabel(String source) {
    switch (source) {
      case 'kbbi':
        return 'KBBI';
      case 'kbbi_edited':
        return 'KBBI (disunting)';
      default:
        return null;
    }
  }
}

class _TranslationList extends StatelessWidget {
  final List<MeaningTranslation> translations;

  const _TranslationList({required this.translations});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Terjemahan',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: translations
              .map(
                (translation) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    translation.translationText,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ExampleBlock extends StatelessWidget {
  final Example example;

  const _ExampleBlock({required this.example});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            example.sourceSentence,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (example.targetSentence != null &&
              example.targetSentence!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              example.targetSentence!,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ],
          if (example.sourceReference != null &&
              example.sourceReference!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Sumber: ${example.sourceReference}',
              style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _RelationList extends StatelessWidget {
  final List<LexicalRelationWithWord> relations;

  const _RelationList({required this.relations});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: relations
          .map(
            (relation) => ActionChip(
              avatar: const Icon(Icons.link_rounded, size: 15),
              label: Text(
                '${relationTypeLabel(relation.relation.relationType)} · '
                '${relation.targetWord.lemma}',
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WordDetailPage(
                    wordId: relation.targetWord.id,
                    initialLemma: relation.targetWord.lemma,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final bool subtle;

  const _Tag({required this.text, this.subtle = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: subtle
            ? AppColors.accent.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: subtle ? AppColors.accent : AppColors.primary,
        ),
      ),
    );
  }
}

class _SurfaceBox extends StatelessWidget {
  final Widget child;

  const _SurfaceBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}
