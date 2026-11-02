import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../models/database_status.dart';
import '../../domain/services/database_update_service.dart';
import '../../utils/constants.dart';
import '../providers/app_providers.dart';
import '../providers/database_update_controller.dart';
import '../providers/settings_providers.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/database_required_view.dart';
import '../widgets/loading_state.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbStatus = ref.watch(databaseStatusProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final online = ref.watch(isOnlineProvider);
    final updateState = ref.watch(updateCheckControllerProvider);
    final installState = ref.watch(databaseUpdateControllerProvider);

    final status = dbStatus.valueOrNull;
    final isReady = status?.isReady ?? false;
    final isBusy = updateState.isChecking || installState.isRunning;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const Text(
            'Pengaturan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 18),
          _AppCard(packageInfo: packageInfo),
          const SizedBox(height: 14),
          _SettingCard(
            icon: Icons.storage_rounded,
            title: 'Database Kamus',
            children: [
              dbStatus.when(
                loading: () => const LoadingState(message: 'Memuat status...'),
                error: (_, _) =>
                    const InfoRow(label: 'Status', value: 'Gagal dibaca'),
                data: (status) => _DatabaseInfo(status: status),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isBusy
                      ? null
                      : isReady
                      ? () => _manualCheck(context, ref)
                      : () => _install(context, ref),
                  icon: isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isReady
                              ? Icons.cloud_download_outlined
                              : Icons.install_mobile_rounded,
                          size: 19,
                        ),
                  label: Text(
                    isReady
                        ? (updateState.isChecking
                              ? 'Memeriksa...'
                              : 'Periksa Pembaruan')
                        : (installState.isRunning
                              ? 'Memasang...'
                              : status?.readiness == DatabaseReadiness.invalid
                              ? 'Pasang Ulang Database'
                              : 'Pasang Database'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isReady
                    ? 'Pemeriksaan membutuhkan koneksi internet. Pencarian '
                          'tetap dapat digunakan secara offline.'
                    : 'Database kamus perlu diunduh sekali (sekitar 1,3 MB). '
                          'Setelah terpasang, seluruh kamus dapat digunakan '
                          'tanpa internet.',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingCard(
            icon: online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            title: 'Koneksi Internet',
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: online ? AppColors.success : AppColors.muted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    online ? 'Terhubung' : 'Tidak terhubung',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Kamus tetap berfungsi tanpa internet. Koneksi hanya '
                'dibutuhkan untuk memeriksa dan mengunduh pembaruan database.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingCard(
            icon: Icons.info_outline_rounded,
            title: 'Tentang Dataset',
            children: const [
              InfoRow(label: 'Sumber', value: 'SambasKu Database'),
              InfoRow(label: 'Lisensi aplikasi', value: 'MIT'),
              InfoRow(
                label: 'Repositori',
                value: 'github.com/sambasku/database',
              ),
              SizedBox(height: 8),
              SelectableText(
                AppConstants.activeMetadataUrl,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 10.5,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Data kamus mengikuti kebijakan editorial SambasKu. Aplikasi '
                'ini tidak menyimpan data pribadi dan tidak mengubah dataset '
                'sumber.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _manualCheck(BuildContext context, WidgetRef ref) async {
    await ref.read(updateCheckControllerProvider.notifier).check();
    if (!context.mounted) return;

    final state = ref.read(updateCheckControllerProvider);
    if (state.error != null) {
      await _showDialog(
        context,
        title: 'Pemeriksaan gagal',
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.danger,
        message: state.error!,
      );
      return;
    }

    final result = state.result;
    if (result == null) return;

    if (!result.updateAvailable) {
      await _showDialog(
        context,
        title: 'Database sudah terbaru',
        icon: Icons.verified_rounded,
        iconColor: AppColors.success,
        message:
            'Anda menggunakan database versi v${result.installedReleaseVersion}. '
            'Tidak ada pembaruan yang tersedia saat ini.',
      );
      return;
    }

    final installed = result.installedReleaseVersion;
    final install = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.system_update_rounded,
          color: AppColors.primary,
          size: 32,
        ),
        title: const Text(
          'Pembaruan database tersedia',
          textAlign: TextAlign.center,
        ),
        content: Text(
          installed == 0
              ? 'Database versi v${result.remote.releaseVersion} siap '
                    'dipasang. Unduhan sekitar '
                    '${formatBytes(result.remote.database.size)} dan '
                    'memerlukan koneksi internet.'
              : 'Versi terbaru v${result.remote.releaseVersion} tersedia '
                    '(database lokal v$installed). Unduhan sekitar '
                    '${formatBytes(result.remote.database.size)}.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Pasang Sekarang'),
          ),
        ],
      ),
    );

    if (install != true || !context.mounted) return;
    await _install(context, ref);
  }

  Future<void> _install(BuildContext context, WidgetRef ref) async {
    ref.read(databaseUpdateControllerProvider.notifier).reset();
    final job = ref
        .read(databaseUpdateControllerProvider.notifier)
        .installLatest();

    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _UpdateProgressDialog(),
    );

    final outcome = await job;
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (outcome.success) {
      _invalidateKamus(ref);
      if (!context.mounted) return;
      ref.read(databaseUpdateControllerProvider.notifier).reset();

      final message = outcome.alreadyLatest
          ? 'Database sudah versi terbaru.'
          : 'Database v${outcome.metadata?.releaseVersion} berhasil dipasang.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    ref.read(databaseUpdateControllerProvider.notifier).reset();
    await _showDialog(
      context,
      title: 'Pemasangan gagal',
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.danger,
      message: outcome.error ?? 'Database tidak dapat dipasang.',
    );
  }

  void _invalidateKamus(WidgetRef ref) {
    ref.invalidate(databaseStatusProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(dailyWordProvider);
    ref.invalidate(randomWordProvider);
    ref.invalidate(dailyWordSummaryProvider);
    ref.invalidate(randomWordSummaryProvider);
  }

  Future<void> _showDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(icon, color: iconColor, size: 32),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}

class _UpdateProgressDialog extends ConsumerWidget {
  const _UpdateProgressDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(databaseUpdateControllerProvider);
    final progress = state.progress;
    final isDownloading = progress?.phase == DatabaseUpdatePhase.downloading;
    final total = progress?.total;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Memasang Database'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: isDownloading ? progress?.fraction : null,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              progress?.message ?? 'Menyiapkan...',
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.4),
            ),
            if (isDownloading && total != null && total > 0) ...[
              const SizedBox(height: 6),
              Text(
                '${formatBytes(progress?.received ?? 0)} / '
                '${formatBytes(total)}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Jangan tutup aplikasi sampai proses selesai.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final AsyncValue<PackageInfo> packageInfo;

  const _AppCard({required this.packageInfo});

  @override
  Widget build(BuildContext context) {
    final version = packageInfo.valueOrNull;
    final versionText = version == null
        ? '–'
        : '${version.version} (${version.buildNumber})';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppConstants.appTagline} · v$versionText',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DatabaseInfo extends StatelessWidget {
  final DatabaseStatus status;

  const _DatabaseInfo({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status.readiness == DatabaseReadiness.notInstalled) {
      return const InfoRow(label: 'Status', value: 'Belum terpasang');
    }
    if (status.readiness == DatabaseReadiness.invalid) {
      return InfoRow(
        label: 'Status',
        value: 'Tidak valid',
        trailing: const Icon(
          Icons.error_outline_rounded,
          size: 16,
          color: AppColors.danger,
        ),
      );
    }
    return Column(
      children: [
        InfoRow(
          label: 'Status',
          value: 'Siap digunakan',
          trailing: const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.success,
          ),
        ),
        InfoRow(
          label: 'Versi database',
          value: status.releaseVersion != null
              ? 'v${status.releaseVersion}'
              : '–',
        ),
        InfoRow(
          label: 'Schema',
          value: status.schemaVersion?.toString() ?? '–',
        ),
        InfoRow(
          label: 'Jumlah kosakata',
          value: '${formatNumber(status.wordCount)} kata',
        ),
        InfoRow(label: 'Dirilis', value: formatIsoDate(status.releasedAt)),
        InfoRow(label: 'Channel', value: status.channel ?? '–'),
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SettingCard({
    required this.icon,
    required this.title,
    required this.children,
  });

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
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}
