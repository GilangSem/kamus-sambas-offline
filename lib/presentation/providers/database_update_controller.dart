import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/services/database_update_service.dart';
import 'app_providers.dart';
import 'settings_providers.dart';

class DatabaseUpdateState {
  final bool isRunning;
  final DatabaseUpdateProgress? progress;
  final DatabaseUpdateOutcome? outcome;

  const DatabaseUpdateState({
    this.isRunning = false,
    this.progress,
    this.outcome,
  });

  DatabaseUpdateState copyWith({
    bool? isRunning,
    DatabaseUpdateProgress? progress,
    DatabaseUpdateOutcome? outcome,
  }) {
    return DatabaseUpdateState(
      isRunning: isRunning ?? this.isRunning,
      progress: progress ?? this.progress,
      outcome: outcome ?? this.outcome,
    );
  }

  bool get isCompleted => !isRunning && outcome != null;
}

/// Controller alur unduh + verifikasi + pasang database.
class DatabaseUpdateController extends StateNotifier<DatabaseUpdateState> {
  final DatabaseUpdateService service;
  final Future<PackageInfo> Function() packageInfo;

  DatabaseUpdateController({required this.service, required this.packageInfo})
    : super(const DatabaseUpdateState());

  Future<DatabaseUpdateOutcome> installLatest() async {
    final current = state.outcome;
    if (state.isRunning) {
      return current ??
          DatabaseUpdateOutcome.failure('Pemasangan lain sedang berjalan.');
    }

    state = const DatabaseUpdateState(
      isRunning: true,
      progress: DatabaseUpdateProgress(
        phase: DatabaseUpdatePhase.checking,
        message: 'Menyiapkan pembaruan...',
      ),
    );

    try {
      final info = await packageInfo();
      final outcome = await service.installLatest(
        currentAppVersion: info.version,
        onProgress: (progress) {
          if (!mounted) return;
          state = state.copyWith(progress: progress);
        },
      );

      if (!mounted) return outcome;
      state = DatabaseUpdateState(outcome: outcome);
      return outcome;
    } catch (e) {
      final outcome = DatabaseUpdateOutcome.failure(
        'Gagal menyiapkan pembaruan: $e',
      );
      if (!mounted) return outcome;
      state = DatabaseUpdateState(outcome: outcome);
      return outcome;
    }
  }

  void reset() {
    if (state.isRunning) return;
    state = const DatabaseUpdateState();
  }
}

final databaseUpdateServiceProvider = Provider<DatabaseUpdateService>((ref) {
  return DatabaseUpdateService(
    network: ref.watch(networkSourceProvider),
    kamusRepository: ref.watch(kamusRepositoryProvider),
    installer: ref.watch(databaseInstallerProvider),
    appMetadata: ref.watch(appMetadataRepositoryProvider),
  );
});

final databaseUpdateControllerProvider =
    StateNotifierProvider<DatabaseUpdateController, DatabaseUpdateState>((ref) {
      return DatabaseUpdateController(
        service: ref.watch(databaseUpdateServiceProvider),
        packageInfo: () => ref.read(packageInfoProvider.future),
      );
    });
