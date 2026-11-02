import 'package:flutter/material.dart';

import '../../models/database_status.dart';
import '../theme/app_theme.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 13.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Tampilan ketika database kamus belum siap digunakan.
class DatabaseRequiredView extends StatelessWidget {
  final DatabaseStatus status;
  final VoidCallback onOpenSettings;

  const DatabaseRequiredView({
    super.key,
    required this.status,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isInvalid = status.readiness == DatabaseReadiness.invalid;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isInvalid
                    ? Icons.report_gmailerrorred_rounded
                    : Icons.menu_book_rounded,
                size: 38,
                color: isInvalid ? AppColors.danger : AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isInvalid
                  ? 'Database kamus tidak valid'
                  : 'Database kamus belum terpasang',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isInvalid
                  ? 'Berkas database yang ada gagal divalidasi. Buka Pengaturan '
                        'untuk memasang ulang database kamus.'
                  : 'Unduh database kamus sekali melalui Pengaturan. Setelah '
                        'terpasang, seluruh pencarian dan detail kata dapat '
                        'digunakan tanpa internet.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13.5,
                height: 1.6,
              ),
            ),
            if (isInvalid && status.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings_rounded, size: 20),
              label: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      ),
    );
  }
}
