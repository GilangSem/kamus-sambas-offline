import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/search_controller.dart';
import '../providers/settings_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/database_required_view.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/word_tile.dart';
import 'word_detail_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final seed = ref.read(searchSeedProvider);
      if (seed != null && seed.trim().isNotEmpty) {
        _applySeed(seed);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _applySeed(String seed) {
    if (!mounted) return;
    _textController.text = seed;
    _textController.selection = TextSelection.collapsed(offset: seed.length);
    final controller = ref.read(searchControllerProvider.notifier);
    controller.updateQuery(seed);
    controller.submit();
    ref.read(searchSeedProvider.notifier).state = null;
  }

  void _clearQuery() {
    _textController.clear();
    ref.read(searchControllerProvider.notifier).clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(searchSeedProvider, (previous, next) {
      if (next != null && next.trim().isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _applySeed(next));
      }
    });

    final state = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);
    final dbStatus = ref.watch(databaseStatusProvider);

    if (dbStatus.isLoading) {
      return const SafeArea(
        child: LoadingState(message: 'Menyiapkan kamus...'),
      );
    }

    final status = dbStatus.valueOrNull;
    if (status != null && !status.isReady) {
      return SafeArea(
        child: DatabaseRequiredView(
          status: status,
          onOpenSettings: () =>
              ref.read(selectedTabProvider.notifier).state = 4,
        ),
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Text(
              'Cari Kata',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onChanged: controller.updateQuery,
              onSubmitted: (_) => controller.submit(),
              decoration: InputDecoration(
                hintText: state.mode == SearchMode.sambas
                    ? 'Cari kata Bahasa Sambas...'
                    : 'Cari arti Bahasa Indonesia...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: state.query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: _clearQuery,
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<SearchMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: SearchMode.sambas,
                        label: Text('Sambas'),
                        icon: Icon(Icons.translate_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: SearchMode.indonesia,
                        label: Text('Indonesia'),
                        icon: Icon(Icons.abc_rounded, size: 16),
                      ),
                    ],
                    selected: {state.mode},
                    onSelectionChanged: (selection) {
                      if (selection.isEmpty) return;
                      controller.setMode(selection.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(child: _buildResults(state, controller)),
        ],
      ),
    );
  }

  Widget _buildResults(SearchState state, SearchController controller) {
    if (state.error != null) {
      return ErrorState(
        message: state.error!,
        onRetry: () => controller.submit(),
      );
    }

    if (state.isLoading) {
      return const LoadingState(message: 'Mencari kata...');
    }

    if (state.query.trim().isEmpty) {
      return const EmptyState(
        icon: Icons.search_rounded,
        title: 'Mulai mencari',
        message:
            'Ketik sebagian kata Bahasa Sambas atau arti Bahasa Indonesia. '
            'Pencarian bekerja sepenuhnya offline.',
      );
    }

    if (!state.hasSearched) {
      return const SizedBox.shrink();
    }

    if (state.results.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Kata tidak ditemukan',
        message:
            'Coba kata lain, periksa ejaan, atau ubah mode pencarian antara '
            'Sambas dan Indonesia.',
      );
    }

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: state.results.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              '${state.results.length} hasil untuk "${state.query.trim()}"',
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          );
        }
        final result = state.results[index - 1];
        return WordTile(
          result: result,
          onTap: () {
            controller.rememberQuery();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WordDetailPage(
                  wordId: result.word.id,
                  initialLemma: result.word.lemma,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
