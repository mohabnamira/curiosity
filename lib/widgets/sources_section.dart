import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/providers/chat_provider.dart';
import 'package:curiosity/theme/colors.dart';

const List<Source> _noSources = <Source>[];

class SourcesSection extends ConsumerStatefulWidget {
  const SourcesSection({super.key});

  @override
  ConsumerState<SourcesSection> createState() => _SourcesSectionState();
}

class _SourcesSectionState extends ConsumerState<SourcesSection>
    with SingleTickerProviderStateMixin {
  static const double _cardWidth = 180;
  static const double _cardGap = 12;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    // Sources may already exist (e.g. reopening an old turn): show instantly.
    final hasSources =
        ref.read(chatNotifierProvider).activeTurn?.sources.isNotEmpty ?? false;
    if (hasSources) _animController.value = 1;
  }

  @override
  void dispose() {
    _animController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openSourceUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _scrollToCard(int? index) {
    if (index == null || !_scrollController.hasClients) return;
    final target = index * (_cardWidth + _cardGap);
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(
      chatNotifierProvider.select((s) => s.activeTurn?.sources ?? _noSources),
    );
    final status = ref.watch(
      chatNotifierProvider.select((s) => s.activeTurn?.status),
    );
    final highlightedIndex = ref.watch(
      chatNotifierProvider.select((s) => s.highlightedSourceIndex),
    );

    // Play the entrance animation when sources actually arrive.
    ref.listen<int>(
      chatNotifierProvider.select((s) => s.activeTurn?.sources.length ?? 0),
      (prev, next) {
        if ((prev ?? 0) == 0 && next > 0) _animController.forward(from: 0);
      },
    );

    // Scroll only when the highlight changes, not on every rebuild.
    ref.listen<int?>(
      chatNotifierProvider.select((s) => s.highlightedSourceIndex),
      (prev, next) => _scrollToCard(next),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(Icons.source_outlined, color: Colors.white70),
              SizedBox(width: 8),
              Text(
                'Sources',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (sources.isEmpty && status == TurnStatus.searching)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.submitButton,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Searching web sources...',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          )
        else if (sources.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'No sources found.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          )
        else
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SizedBox(
                width: double.infinity,
                height: 100,
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: sources.length,
                  separatorBuilder: (_, _) => const SizedBox(width: _cardGap),
                  itemBuilder: (context, index) {
                    return _SourceCard(
                      number: index + 1,
                      source: sources[index],
                      width: _cardWidth,
                      isHighlighted: highlightedIndex == index,
                      onTap: () {
                        ref
                            .read(chatNotifierProvider.notifier)
                            .setHighlightedSource(index);
                        _openSourceUrl(sources[index].url);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  final int number;
  final Source source;
  final double width;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _SourceCard({
    required this.number,
    required this.source,
    required this.width,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHighlighted ? Colors.blue.shade400 : Colors.grey.shade800,
            width: isHighlighted ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    source.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              source.url,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}