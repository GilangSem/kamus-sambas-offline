import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/datasources/network_source.dart';
import '../../domain/services/update_check_service.dart';
import 'app_providers.dart';

/// Tab aktif pada shell navigasi.
final selectedTabProvider = StateProvider<int>((ref) => 0);

/// Query awal untuk halaman pencarian (dipakai dari riwayat/kategori).
final searchSeedProvider = StateProvider<String?>((ref) => null);

final networkSourceProvider = Provider<NetworkSource>((ref) {
  final source = NetworkSource();
  ref.onDispose(source.dispose);
  return source;
});

final updateCheckServiceProvider = Provider<UpdateCheckService>((ref) {
  return UpdateCheckService(
    network: ref.watch(networkSourceProvider),
    kamusRepository: ref.watch(kamusRepositoryProvider),
  );
});

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Status online. Saat belum diketahui, dianggap online agar pemeriksaan
/// pembaruan tetap dapat dicoba.
final isOnlineProvider = Provider<bool>((ref) {
  final async = ref.watch(connectivityProvider);
  final results = async.valueOrNull;
  if (results == null || results.isEmpty) return true;
  return results.any((result) => result != ConnectivityResult.none);
});

class UpdateCheckState {
  final bool isChecking;
  final UpdateCheckResult? result;
  final String? error;

  const UpdateCheckState({this.isChecking = false, this.result, this.error});
}

/// Controller pemeriksaan pembaruan manual/otomatis.
class UpdateCheckController extends StateNotifier<UpdateCheckState> {
  final UpdateCheckService _service;

  UpdateCheckController(this._service) : super(const UpdateCheckState());

  Future<void> check() async {
    if (state.isChecking) return;
    state = const UpdateCheckState(isChecking: true);
    try {
      final result = await _service.checkForUpdate();
      if (!mounted) return;
      state = UpdateCheckState(result: result);
    } catch (e) {
      if (!mounted) return;
      state = UpdateCheckState(
        error: e is NetworkException
            ? e.message
            : 'Gagal memeriksa pembaruan. Coba lagi nanti.',
      );
    }
  }
}

final updateCheckControllerProvider =
    StateNotifierProvider<UpdateCheckController, UpdateCheckState>((ref) {
      return UpdateCheckController(ref.watch(updateCheckServiceProvider));
    });
