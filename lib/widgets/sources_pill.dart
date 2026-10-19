import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/providers/settings_provider.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/citation_chip.dart';

class SourcesPill extends ConsumerStatefulWidget {
  final List<Source> sources;
  final int? researchedSeconds;
  final bool isSearching;
  final VoidCallback onTap;

  const SourcesPill({
    super.key,
    required this.sources,
    this.researchedSeconds,
    required this.isSearching,
    required this.onTap,
  });

  @override
  ConsumerState<SourcesPill> createState() => _SourcesPillState();
}

class _SourcesPillState extends ConsumerState<SourcesPill>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isSearching) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(SourcesPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSearching && !_shimmerController.isAnimating) {
      _shimmerController.repeat();
    } else if (!widget.isSearching && _shimmerController.isAnimating) {
      _shimmerController.stop();
      _shimmerController.value = 0;
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Widget _buildFaviconItem(Source source, int index) {
    const double size = 18;
    final domain = cleanDomain(source.url);
    final initial = domain.isNotEmpty ? domain[0].toUpperCase() : '${index + 1}';
    final faviconUrl = 'https://www.google.com/s2/favicons?domain=$domain&sz=64';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.background, width: 1.5),
      ),
      child: ClipOval(
        child: Image.network(
          faviconUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: AppColors.border,
            alignment: Alignment.center,
            child: Text(
              initial,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlappingFavicons(List<Source> sources) {
    final preview = sources.take(3).toList();
    const double size = 18;
    const double overlap = 11;
    final totalWidth = size + (preview.length - 1) * overlap;

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < preview.length; i++)
            Positioned(
              left: i * overlap,
              child: _buildFaviconItem(preview[i], i),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSources = widget.sources.isNotEmpty;
    final settings = ref.watch(settingsNotifierProvider);
    final accent = settings.accentColor.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _isHovered ? accent.withValues(alpha: 0.8) : AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: _isHovered ? 0.12 : 0.05),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.isSearching && !hasSources) ...[
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, _) {
                    final alpha = 0.4 + 0.5 * _shimmerController.value;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Searching...',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary.withValues(alpha: alpha),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ] else ...[
                if (hasSources) ...[
                  _buildOverlappingFavicons(widget.sources),
                  const SizedBox(width: 8),
                ],
                Text(
                  hasSources
                      ? '${widget.sources.length} sources · Researched ${widget.researchedSeconds ?? 1}s'
                      : (widget.researchedSeconds != null
                          ? 'Researched ${widget.researchedSeconds}s'
                          : 'Sources'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.normal,
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
