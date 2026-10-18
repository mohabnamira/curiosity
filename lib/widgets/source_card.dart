import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/citation_chip.dart';

class SourceCard extends StatelessWidget {
  final Source source;
  final int index;
  final bool isHighlighted;

  const SourceCard({
    super.key,
    required this.source,
    required this.index,
    required this.isHighlighted,
  });

  Future<void> _launch() async {
    final uri = Uri.tryParse(source.url.trim());
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final domain = cleanDomain(source.url);
    final initial = domain.isNotEmpty ? domain[0].toUpperCase() : '${index + 1}';
    final faviconUrl = 'https://www.google.com/s2/favicons?domain=$domain&sz=64';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _launch,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isHighlighted ? AppColors.focus : AppColors.border,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Favicon + Domain row
              Row(
                children: [
                  ClipOval(
                    child: Image.network(
                      faviconUrl,
                      width: 20,
                      height: 20,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      domain,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Title (Inter 14px semi-bold, max 2 lines)
              Text(
                source.title.isNotEmpty ? source.title : domain,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (source.snippet.isNotEmpty) ...[
                const SizedBox(height: 4),
                // Snippet (textSecondary, 13px, max 3 lines)
                Text(
                  source.snippet,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
