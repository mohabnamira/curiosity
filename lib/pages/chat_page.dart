import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/providers/chat_provider.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/answer_view.dart';
import 'package:curiosity/widgets/query_input.dart';
import 'package:curiosity/widgets/side_bar.dart';
import 'package:curiosity/widgets/source_card.dart';
import 'package:curiosity/widgets/sources_panel.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final TabController _tabController;

  String? _highlightTurnId;
  int? _highlightIndex;
  bool _showScrollToBottom = false;
  bool _userScrolledUp = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    final isNearBottom = (max - current) < 120;

    if (isNearBottom && _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = false;
        _userScrolledUp = false;
      });
    } else if (!isNearBottom && !_showScrollToBottom) {
      setState(() {
        _showScrollToBottom = true;
        _userScrolledUp = true;
      });
    }
  }

  void _scrollToBottom() {
    if (_userScrolledUp) return; // Do not yank view if user is reading older content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _forceScrollToBottom() {
    setState(() => _userScrolledUp = false);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _ask(String query) {
    ref.read(chatNotifierProvider.notifier).sendQuery(query);
  }

  void _highlight(String turnId, int index) {
    setState(() {
      _highlightTurnId = turnId;
      _highlightIndex = index;
    });
    ref.read(chatNotifierProvider.notifier).setActiveTurn(turnId);
    ref.read(chatNotifierProvider.notifier).setHighlightedSource(index);
  }

  @override
  Widget build(BuildContext context) {
    final turns = ref.watch(chatNotifierProvider.select((s) => s.turns));
    final activeTurn = ref.watch(chatNotifierProvider.select((s) => s.activeTurn)) ??
        (turns.isNotEmpty ? turns.last : null);

    ref.listen(
      chatNotifierProvider.select((s) => s.turns.length),
      (_, _) {
        setState(() => _userScrolledUp = false);
        _scrollToBottom();
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 800;
        final showRightColumn = width >= 1100;

        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: isMobile
              ? const Drawer(
                  backgroundColor: AppColors.surface,
                  child: SideBar(isDrawer: true),
                )
              : null,
          appBar: isMobile
              ? AppBar(
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: AppColors.textPrimary),
                )
              : null,
          body: Row(
            children: [
              if (!isMobile) const SideBar(),
              Expanded(
                child: Column(
                  children: [
                    // Top Bar with Answer | Links | Images tabs
                    _buildTopTabBar(),
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // 1. Answer View
                          _buildConversationBody(turns, activeTurn, showRightColumn, isMobile),
                          // 2. Links View
                          _buildLinksView(activeTurn),
                          // 3. Images View
                          _buildImagesView(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopTabBar() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppColors.focus,
        indicatorWeight: 2,
        dividerColor: Colors.transparent,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        tabs: const [
          Tab(text: 'Answer'),
          Tab(text: 'Links'),
          Tab(text: 'Images'),
        ],
      ),
    );
  }

  Widget _buildConversationBody(
    List<Turn> turns,
    Turn? activeTurn,
    bool showRightColumn,
    bool isMobile,
  ) {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Center conversation column (max ~760px, centered)
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 140),
                    itemCount: turns.length,
                    itemBuilder: (context, index) {
                      final turn = turns[index];
                      final isHighlightedForTurn = _highlightTurnId == turn.id;

                      return AnswerView(
                        turn: turn,
                        isLatest: index == turns.length - 1,
                        showInlineSources: !showRightColumn,
                        highlightedSourceIndex:
                            isHighlightedForTurn ? _highlightIndex : null,
                        onAskQuery: _ask,
                        onHighlightSource: (sIndex) => _highlight(turn.id, sIndex),
                        onRetry: () => _ask(turn.question),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Right column (~340px) for Sources card on desktop >= 1100px
            if (showRightColumn)
              Container(
                width: 340,
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: activeTurn != null && activeTurn.sources.isNotEmpty
                    ? SourcesPanel(
                        sources: activeTurn.sources,
                        highlightedIndex: _highlightTurnId == activeTurn.id
                            ? _highlightIndex
                            : null,
                      )
                    : Center(
                        child: Text(
                          'No sources for this turn',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
              ),
          ],
        ),
        // Floating circular scroll-to-bottom button
        if (_showScrollToBottom)
          Positioned(
            bottom: 110,
            right: showRightColumn ? 360 : 28,
            child: Tooltip(
              message: 'Scroll to bottom',
              child: InkWell(
                onTap: _forceScrollToBottom,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        // Sticky bottom input bar with gradient fade and blur
        Positioned(
          left: 0,
          right: showRightColumn ? 340 : 0,
          bottom: 0,
          child: _buildStickyInputBar(),
        ),
      ],
    );
  }

  Widget _buildStickyInputBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 32px gradient fade: transparent to background so text scrolls under
        Container(
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.0),
                AppColors.background,
              ],
            ),
          ),
        ),
        // BackdropFilter blur (sigma ~12) container with QueryInput
        ClipRect(
          child: Container(
            color: AppColors.background.withValues(alpha: 0.85),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: QueryInput(
                hintText: 'Ask a follow-up...',
                onSubmit: _ask,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinksView(Turn? activeTurn) {
    if (activeTurn == null || activeTurn.sources.isEmpty) {
      return Center(
        child: Text(
          'No sources for the current turn',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: activeTurn.sources.length,
          itemBuilder: (context, index) {
            return SourceCard(
              source: activeTurn.sources[index],
              index: index,
              isHighlighted: false,
            );
          },
        ),
      ),
    );
  }

  Widget _buildImagesView() {
    // TODO(backend): include_images in Tavily + new message type
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.image_outlined,
            size: 48,
            color: AppColors.iconMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'Images coming soon',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Image search results will appear here once backend support is ready.',
            style: GoogleFonts.inter(
              color: AppColors.iconMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}