import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/category_with_count.dart';
import '../../models/database_status.dart';
import '../../models/search_result.dart';
import '../providers/app_providers.dart';
import '../providers/settings_providers.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/database_required_view.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/section_title.dart';
import 'categories_page.dart';
import 'category_words_page.dart';
import 'word_detail_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbStatus = ref.watch(databaseStatusProvider);

    return SafeArea(
      child: dbStatus.when(
        loading: () => const LoadingState(message: 'Menyiapkan kamus...'),
        error: (error, _) => ErrorState(
          message: 'Gagal memuat status database.',
          onRetry: () => ref.invalidate(databaseStatusProvider),
        ),
        data: (status) {
          if (!status.isReady) {
            return DatabaseRequiredView(
              status: status,
              onOpenSettings: () =>
                  ref.read(selectedTabProvider.notifier).state = 4,
            );
          }
          return _HomeContent(status: status);
        },
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  final DatabaseStatus status;

  const _HomeContent({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daily = ref.watch(dailyWordSummaryProvider);
    final random = ref.watch(randomWordSummaryProvider);
    final categories = ref.watch(categoriesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(databaseStatusProvider);
        ref.invalidate(categoriesProvider);
        ref.invalidate(randomWordProvider);
        await ref.read(databaseStatusProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const _Header(),
          const SizedBox(height: 20),
          _SearchLauncher(
            onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
          ),
          const SizedBox(height: 20),
          _SummaryCard(status: status),
          const SizedBox(height: 26),
          SectionTitle(
            title: 'Kata Hari Ini',
            subtitle: 'Satu kata untuk menemani hari Anda',
          ),
          const SizedBox(height: 12),
          _WordHighlight(
            async: daily,
            emptyMessage: 'Belum ada kata untuk hari ini.',
            icon: Icons.wb_sunny_outlined,
            accent: AppColors.accent,
            onTap: (result) => _openWord(context, result.word.id),
            onRetry: () => ref.invalidate(dailyWordProvider),
          ),
          const SizedBox(height: 24),
          SectionTitle(
            title: 'Kata Acak',
            subtitle: 'Jelajahi kosakata baru',
            trailing: IconButton(
              tooltip: 'Acak lagi',
              onPressed: () => ref.invalidate(randomWordProvider),
              icon: const Icon(Icons.refresh_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          _WordHighlight(
            async: random,
            emptyMessage: 'Belum ada kata untuk ditampilkan.',
            icon: Icons.shuffle_rounded,
            accent: AppColors.primary,
            onTap: (result) => _openWord(context, result.word.id),
            onRetry: () => ref.invalidate(randomWordProvider),
          ),
          const SizedBox(height: 26),
          SectionTitle(
            title: 'Jelajahi Kategori',
            subtitle: 'Temukan kosakata berdasarkan topik',
            trailing: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CategoriesPage())),
              child: const Text('Semua'),
            ),
          ),
          const SizedBox(height: 12),
          categories.when(
            loading: () => const SizedBox(
              height: 92,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            ),
            error: (_, _) => const Text(
              'Kategori tidak dapat dimuat.',
              style: TextStyle(color: AppColors.muted),
            ),
            data: (list) => _CategoryStrip(categories: list),
          ),
          const SizedBox(height: 26),
          _DatabaseCard(
            status: status,
            onOpenSettings: () =>
                ref.read(selectedTabProvider.notifier).state = 4,
          ),
        ],
      ),
    );
  }

  void _openWord(BuildContext context, String wordId) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => WordDetailPage(wordId: wordId)));
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kamus Bahasa Sambas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Sambas – Indonesia · Offline',
                style: TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.offline_bolt_rounded,
                size: 14,
                color: AppColors.success,
              ),
              SizedBox(width: 4),
              Text(
                'Offline',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchLauncher extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchLauncher({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.muted, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cari kata Sambas atau arti Indonesia',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
              ),
              Icon(Icons.tune_rounded, color: AppColors.muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final DatabaseStatus status;

  const _SummaryCard({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const Row(
            children: [
              Icon(
                Icons.auto_stories_outlined,
                color: Colors.white70,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Kosakata tersedia',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatNumber(status.wordCount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'kata dalam Bahasa Sambas',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                status.releaseVersion != null
                    ? 'Versi database v${status.releaseVersion}'
                    : 'Versi database –',
              ),
              if (status.channel != null) _pill(_channelLabel(status.channel!)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
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

  String _channelLabel(String channel) {
    switch (channel) {
      case 'production':
        return 'Rilis production';
      case 'staging':
        return 'Rilis staging';
      default:
        return capitalize(channel);
    }
  }
}

class _WordHighlight extends StatelessWidget {
  final AsyncValue<SearchResult?> async;
  final String emptyMessage;
  final IconData icon;
  final Color accent;
  final ValueChanged<SearchResult> onTap;
  final VoidCallback onRetry;

  const _WordHighlight({
    required this.async,
    required this.emptyMessage,
    required this.icon,
    required this.accent,
    required this.onTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const SizedBox(
        height: 92,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      ),
      error: (_, _) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Tidak dapat dimuat',
        message: 'Terjadi kesalahan saat mengambil kata.',
        actionLabel: 'Coba lagi',
        onAction: onRetry,
      ),
      data: (result) {
        if (result == null) {
          return Text(
            emptyMessage,
            style: const TextStyle(color: AppColors.muted),
          );
        }
        final glosses = result.translations.take(3).join(' · ');
        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => onTap(result),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.word.lemma,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (glosses.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            glosses,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.muted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final List<CategoryWithCount> categories;

  const _CategoryStrip({required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Text(
        'Belum ada kategori.',
        style: TextStyle(color: AppColors.muted),
      );
    }

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = categories[index];
          return SizedBox(
            width: 156,
            child: Material(
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.local_offer_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const Spacer(),
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatNumber(item.wordCount)} kata',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DatabaseCard extends StatelessWidget {
  final DatabaseStatus status;
  final VoidCallback onOpenSettings;

  const _DatabaseCard({required this.status, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.storage_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Status Database',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: onOpenSettings,
                child: const Text('Pengaturan'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _row(
            'Versi database',
            status.releaseVersion != null
                ? 'v${status.releaseVersion} (schema ${status.schemaVersion})'
                : '–',
          ),
          _row('Jumlah kosakata', '${formatNumber(status.wordCount)} kata'),
          _row('Dirilis', formatIsoDate(status.releasedAt)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
