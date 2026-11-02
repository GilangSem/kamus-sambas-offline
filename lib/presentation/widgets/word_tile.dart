import 'package:flutter/material.dart';

import '../../models/search_result.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class WordTile extends StatelessWidget {
  final SearchResult result;
  final VoidCallback? onTap;
  final Widget? trailing;

  const WordTile({super.key, required this.result, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final glosses = result.translations.take(3).toList();
    final subtitle = glosses.isEmpty
        ? 'Belum ada terjemahan'
        : glosses.join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          result.word.lemma,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (result.word.wordType != 'word')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            wordTypeLabel(result.word.wordType),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                    size: 20,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
