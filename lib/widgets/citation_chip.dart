import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curiosity/providers/settings_provider.dart';
import 'package:curiosity/theme/colors.dart';

String cleanDomain(String url) {
  try {
    final uri = Uri.parse(url.trim());
    var host = uri.host.toLowerCase();
    if (host.startsWith('www.')) {
      host = host.substring(4);
    }
    return host.isNotEmpty ? host : url;
  } catch (_) {
    return url;
  }
}

class CitationGroupWidget extends ConsumerWidget {
  final List<int> sourceIndices; // 0-based source indices
  final List<String> sourceUrls;
  final ValueChanged<int>? onCitationTap;

  const CitationGroupWidget({
    super.key,
    required this.sourceIndices,
    required this.sourceUrls,
    this.onCitationTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sourceIndices.isEmpty) return const SizedBox.shrink();

    final settings = ref.watch(settingsNotifierProvider);
    final accent = settings.accentColor.color;
    final firstIndex = sourceIndices.first;
    final firstUrl = (firstIndex >= 0 && firstIndex < sourceUrls.length)
        ? sourceUrls[firstIndex]
        : '';
    final domain = cleanDomain(firstUrl);
    final extraCount = sourceIndices.length - 1;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (onCitationTap != null) {
            onCitationTap!(firstIndex);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.language_rounded,
                size: 11,
                color: accent == Colors.white ? AppColors.iconMuted : accent,
              ),
              const SizedBox(width: 4),
              Text(
                domain.isNotEmpty ? domain : '${firstIndex + 1}',
                style: const TextStyle(
                  fontFamily: 'Fira Code',
                  fontSize: 11,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              if (extraCount > 0) ...[
                Text(
                  ' +$extraCount',
                  style: const TextStyle(
                    fontFamily: 'Fira Code',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
