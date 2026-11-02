import '../../data/datasources/network_source.dart';
import '../../data/repositories/kamus_repository.dart';
import '../../models/update_metadata.dart';

/// Hasil pemeriksaan pembaruan database.
class UpdateCheckResult {
  final bool updateAvailable;
  final UpdateMetadata remote;
  final int installedReleaseVersion;

  const UpdateCheckResult({
    required this.updateAvailable,
    required this.remote,
    required this.installedReleaseVersion,
  });
}

/// Layanan pemeriksaan pembaruan database kamus.
///
/// TAHAP ini hanya memeriksa ketersediaan metadata rilis; proses unduh,
/// verifikasi, dan pemasangan ditangani pada tahap sistem pembaruan.
class UpdateCheckService {
  final NetworkSource network;
  final KamusRepository kamusRepository;

  UpdateCheckService({NetworkSource? network, required this.kamusRepository})
    : network = network ?? NetworkSource();

  Future<UpdateCheckResult> checkForUpdate() async {
    final remote = await network.fetchActiveMetadata();

    var installed = 0;
    try {
      final meta = await kamusRepository.getReleaseMeta();
      installed = int.tryParse(meta['release_version'] ?? '') ?? 0;
    } catch (_) {
      // Database belum terpasang / tidak dapat dibaca. Perlakukan sebagai
      // belum memiliki versi sehingga versi terbaru dianggap tersedia.
      installed = 0;
    }

    return UpdateCheckResult(
      updateAvailable: remote.releaseVersion > installed,
      remote: remote,
      installedReleaseVersion: installed,
    );
  }
}
