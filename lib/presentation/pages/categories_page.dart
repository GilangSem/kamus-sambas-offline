import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import 'category_words_page.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kategori')),
      body: categories.when(
        loading: () => const LoadingState(message: 'Memuat kategori...'),
        error: (_, _) => ErrorState(
          message: 'Kategori tidak dapat dimuat.',
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.local_offer_outlined,
              title: 'Belum ada kategori',
              message: 'Kategori kosakata belum tersedia pada database ini.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = list[index];
              return Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CategoryWordsPage(
                        categoryId: item.id,
                        categoryName: item.name,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_offer_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (item.description != null &&
                                  item.description!.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          formatNumber(item.wordCount),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.muted,
                          size: 20,
                        ),
                      ],
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
