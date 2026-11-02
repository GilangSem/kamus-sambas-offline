import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/favorites_controller.dart';
import '../providers/settings_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/database_required_view.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/word_tile.dart';
import 'word_detail_page.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbStatus = ref.watch(databaseStatusProvider);
    final favorites = ref.watch(favoritesControllerProvider);
    final words = ref.watch(favoriteWordsProvider);

    if (dbStatus.valueOrNull != null && !dbStatus.valueOrNull!.isReady) {
      return SafeArea(
        child: DatabaseRequiredView(
          status: dbStatus.valueOrNull!,
          onOpenSettings: () =>
              ref.read(selectedTabProvider.notifier).state = 4,
        ),
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                const Text(
                  'Favorit',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(width: 8),
                if (!favorites.isLoading && favorites.count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${favorites.count}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: favorites.isLoading
                ? const LoadingState(message: 'Memuat favorit...')
                : words.when(
                    loading: () =>
                        const LoadingState(message: 'Memuat kata favorit...'),
                    error: (_, _) => const ErrorState(
                      message: 'Daftar favorit tidak dapat dimuat.',
                    ),
                    data: (list) {
                      if (list.isEmpty) {
                        return EmptyState(
                          icon: Icons.favorite_border_rounded,
                          title: 'Belum ada favorit',
                          message:
                              'Simpan kata yang ingin Anda pelajari kembali '
                              'dengan menekan ikon hati pada detail kata.',
                          actionLabel: 'Cari kata',
                          onAction: () =>
                              ref.read(selectedTabProvider.notifier).state = 1,
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
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
                            trailing: IconButton(
                              tooltip: 'Hapus dari favorit',
                              icon: const Icon(
                                Icons.favorite_rounded,
                                color: AppColors.danger,
                                size: 20,
                              ),
                              onPressed: () async {
                                final removed = await ref
                                    .read(favoritesControllerProvider.notifier)
                                    .toggle(result.word.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      removed
                                          ? 'Dihapus dari favorit'
                                          : 'Ditambahkan ke favorit',
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
