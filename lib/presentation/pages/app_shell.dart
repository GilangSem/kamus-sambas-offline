import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/constants.dart';
import '../providers/app_providers.dart';
import '../providers/settings_providers.dart';
import 'favorites_page.dart';
import 'history_page.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'settings_page.dart';

/// Kerangka utama dengan navigasi lima tab.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _autoCheckStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoCheck());
  }

  /// Periksa pembaruan maksimal sekali per [AppConstants.updateCheckInterval].
  /// Kegagalan bersifat non-kritis dan tidak mengganggu pemakaian kamus.
  Future<void> _autoCheck() async {
    if (_autoCheckStarted || !mounted) return;
    _autoCheckStarted = true;

    try {
      final appMetadata = ref.read(appMetadataRepositoryProvider);
      final lastCheck = await appMetadata.getLastUpdateCheck();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (lastCheck != null &&
          now - lastCheck < AppConstants.updateCheckInterval.inSeconds) {
        return;
      }
      if (!ref.read(isOnlineProvider)) return;

      await ref.read(updateCheckControllerProvider.notifier).check();
      await appMetadata.setLastUpdateCheck(now);
      if (!mounted) return;

      final result = ref.read(updateCheckControllerProvider).result;
      if (result == null || !result.updateAvailable) return;

      var ready = false;
      try {
        final status = await ref.read(databaseStatusProvider.future);
        ready = status.isReady;
      } catch (_) {
        ready = false;
      }
      if (!mounted) return;

      final version = result.remote.releaseVersion;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ready
                ? 'Pembaruan database v$version tersedia.'
                : 'Database kamus v$version tersedia. Pasang untuk mulai '
                      'mencari.',
          ),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: ready ? 'Lihat' : 'Pasang',
            onPressed: () => ref.read(selectedTabProvider.notifier).state = 4,
          ),
        ),
      );
    } catch (_) {
      // Pemeriksaan otomatis tidak boleh mengganggu penggunaan aplikasi.
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(selectedTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          HomePage(),
          SearchPage(),
          FavoritesPage(),
          HistoryPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) =>
            ref.read(selectedTabProvider.notifier).state = value,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.saved_search_rounded),
            label: 'Cari',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favorit',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_toggle_off_rounded),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
