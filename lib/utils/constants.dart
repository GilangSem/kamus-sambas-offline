/// Konstanta aplikasi & sumber dataset.
class AppConstants {
  AppConstants._();

  static const String appName = 'Kamus Bahasa Sambas';
  static const String appTagline = 'Kamus Digital Sambas–Indonesia';

  /// Schema publik yang didukung aplikasi ini.
  static const int supportedSchemaVersion = 1;

  /// Pointer rilis aktif (sumber metadata pembaruan).
  static const String activeMetadataUrl =
      'https://raw.githubusercontent.com/sambasku/database/main/metadata/active.json';

  /// Basis URL asset GitHub Release: `.../download/v{N}/`.
  static const String releaseBaseUrl =
      'https://github.com/sambasku/database/releases/download';

  /// Batas waktu request HTTP.
  static const Duration httpTimeout = Duration(seconds: 30);

  /// Interval minimal antar pemeriksaan pembaruan otomatis.
  static const Duration updateCheckInterval = Duration(hours: 12);

  /// Jumlah maksimal hasil pencarian per halaman.
  static const int searchPageSize = 50;

  /// Jumlah maksimal item riwayat pencarian yang ditampilkan.
  static const int maxHistoryItems = 50;
}
