import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/word_tile.dart';
import 'word_detail_page.dart';

class CategoryWordsPage extends ConsumerWidget {
  final String categoryId;
  final String categoryName;

  const CategoryWordsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = ref.watch(categoryWordsProvider(categoryId));

    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: words.when(
        loading: () => const LoadingState(message: 'Memuat kosakata...'),
        error: (_, _) => ErrorState(
          message: 'Kosakata kategori ini tidak dapat dimuat.',
          onRetry: () => ref.invalidate(categoryWordsProvider(categoryId)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Belum ada kata',
              message: 'Kategori ini belum memiliki kosakata.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final result = list[index];
              return WordTile(
                result: result,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WordDetailPage(
                      wordId: result.word.id,
                      initialLemma: result.word.lemma,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
