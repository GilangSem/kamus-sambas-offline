import '../datasources/local_database_source.dart';
import '../../models/app_meta.dart';

/// Repository untuk app metadata operations
class AppMetadataRepository {
  final LocalDatabaseSource _dataSource;

  AppMetadataRepository({LocalDatabaseSource? dataSource})
    : _dataSource = dataSource ?? LocalDatabaseSource();

  Future<void> setDbVersion(String version) async {
    await _dataSource.setAppMeta(AppMeta(key: 'db_version', value: version));
  }

  Future<String?> getDbVersion() => _dataSource.getAppMeta('db_version');

  Future<void> setLastUpdateCheck(int timestamp) async {
    await _dataSource.setAppMeta(
      AppMeta(key: 'last_update_check', value: timestamp.toString()),
    );
  }

  Future<int?> getLastUpdateCheck() async {
    final value = await _dataSource.getAppMeta('last_update_check');
    return value != null ? int.tryParse(value) : null;
  }

  Future<void> setDbPath(String path) async {
    await _dataSource.setAppMeta(AppMeta(key: 'db_path', value: path));
  }

  Future<String?> getDbPath() => _dataSource.getAppMeta('db_path');
}
