import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/database_status.dart';
import '../providers/app_providers.dart';
import '../providers/history_controller.dart';
import '../providers/settings_providers.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/database_required_view.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbStatus = ref.watch(databaseStatusProvider);
    final history = ref.watch(historyControllerProvider);

    if (dbStatus.valueOrNull?.readiness == DatabaseReadiness.notInstalled) {
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
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Riwayat Pencarian',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                if (history.items.isNotEmpty)
                  TextButton(
                    onPressed: () => _confirmClear(context, ref),
                    child: const Text('Hapus semua'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: history.isLoading
                ? const LoadingState(message: 'Memuat riwayat...')
                : history.error != null
                ? ErrorState(
                    message: history.error!,
                    onRetry: () =>
                        ref.read(historyControllerProvider.notifier).load(),
                  )
                : history.items.isEmpty
                ? const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'Belum ada riwayat',
                    message:
                        'Kata yang Anda cari akan muncul di sini untuk '
                        'memudahkan pencarian berikutnya.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: history.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = history.items[index];
                      return InkWell(
                        onTap: () {
                          ref.read(searchSeedProvider.notifier).state =
                              item.query;
                          ref.read(selectedTabProvider.notifier).state = 1;
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.history_rounded,
                                size: 20,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.query,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${formatUnixSeconds(item.timestamp)} · '
                                      '${formatNumber(item.resultCount)} hasil',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Hapus riwayat',
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.muted,
                                ),
                                onPressed: () => ref
                                    .read(historyControllerProvider.notifier)
                                    .remove(item.id!),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus seluruh riwayat?'),
        content: const Text(
          'Semua riwayat pencarian akan dihapus permanen dari perangkat ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(historyControllerProvider.notifier).clearAll();
    }
  }
}
