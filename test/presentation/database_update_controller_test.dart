import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:kamus_app/data/datasources/network_source.dart';
import 'package:kamus_app/data/local/kamus_database_installer.dart';
import 'package:kamus_app/data/repositories/app_metadata_repository.dart';
import 'package:kamus_app/data/repositories/kamus_repository.dart';
import 'package:kamus_app/domain/services/database_update_service.dart';
import 'package:kamus_app/models/update_metadata.dart';
import 'package:kamus_app/presentation/providers/database_update_controller.dart';

class _FakeUpdateService extends DatabaseUpdateService {
  final DatabaseUpdateOutcome outcome;
  final bool shouldThrow;
  String? seenVersion;

  _FakeUpdateService({required this.outcome, this.shouldThrow = false})
    : super(
        network: NetworkSource(
          client: MockClient((_) async => http.Response('', 500)),
        ),
        kamusRepository: KamusRepository(),
        installer: KamusDatabaseInstaller(),
        appMetadata: AppMetadataRepository(),
      );

  @override
  Future<DatabaseUpdateOutcome> installLatest({
    required String currentAppVersion,
    void Function(DatabaseUpdateProgress progress)? onProgress,
  }) async {
    seenVersion = currentAppVersion;
    onProgress?.call(
      const DatabaseUpdateProgress(
        phase: DatabaseUpdatePhase.downloading,
        message: 'Mengunduh...',
        received: 1,
        total: 2,
      ),
    );
    if (shouldThrow) {
      throw StateError('jaringan putus');
    }
    return outcome;
  }
}

UpdateMetadata _metadata() {
  return UpdateMetadata(
    releaseVersion: 2,
    schemaVersion: 1,
    minAppVersion: '0.1.0',
    channel: 'stable',
    releasedAt: DateTime.utc(2026, 1, 1),
    database: DatabaseInfo(
      file: 'database.sqlite.gz',
      url: 'https://example.test/database.sqlite.gz',
      size: 10,
      sha256: 'a' * 64,
    ),
    manifestUrl: 'https://example.test/manifest.json',
  );
}

DatabaseUpdateController _controller(_FakeUpdateService service) {
  return DatabaseUpdateController(
    service: service,
    packageInfo: () async => PackageInfo(
      appName: 'Kamus Sambas',
      packageName: 'id.sambasku.kamus',
      version: '0.1.0',
      buildNumber: '1',
    ),
  );
}

void main() {
  test('memasang database dan menyimpan hasil berhasil', () async {
    final metadata = _metadata();
    final service = _FakeUpdateService(
      outcome: DatabaseUpdateOutcome.success(metadata),
    );
    final controller = _controller(service);
    addTearDown(controller.dispose);

    final outcome = await controller.installLatest();

    expect(outcome.success, isTrue);
    expect(service.seenVersion, '0.1.0');
    expect(controller.state.isRunning, isFalse);
    expect(controller.state.outcome?.metadata?.releaseVersion, 2);
  });

  test('meneruskan kegagalan dari service ke state', () async {
    final service = _FakeUpdateService(
      outcome: DatabaseUpdateOutcome.failure('Checksum tidak cocok.'),
    );
    final controller = _controller(service);
    addTearDown(controller.dispose);

    final outcome = await controller.installLatest();

    expect(outcome.success, isFalse);
    expect(controller.state.outcome?.error, 'Checksum tidak cocok.');
    expect(controller.state.isRunning, isFalse);
  });

  test('exception tidak dibiarkan keluar dari controller', () async {
    final service = _FakeUpdateService(
      outcome: DatabaseUpdateOutcome.failure('tidak dipakai'),
      shouldThrow: true,
    );
    final controller = _controller(service);
    addTearDown(controller.dispose);

    final outcome = await controller.installLatest();

    expect(outcome.success, isFalse);
    expect(outcome.error, contains('jaringan putus'));
    expect(controller.state.isRunning, isFalse);
  });

  test('reset membersihkan hasil setelah selesai', () async {
    final service = _FakeUpdateService(
      outcome: DatabaseUpdateOutcome.success(_metadata()),
    );
    final controller = _controller(service);
    addTearDown(controller.dispose);

    await controller.installLatest();
    controller.reset();

    expect(controller.state.outcome, isNull);
    expect(controller.state.progress, isNull);
    expect(controller.state.isRunning, isFalse);
  });
}
