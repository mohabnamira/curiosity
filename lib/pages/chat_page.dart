import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/pages/home_page.dart';
import 'package:curiosity/providers/chat_provider.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/answer_view.dart';
import 'package:curiosity/widgets/connection_banner.dart';
import 'package:curiosity/widgets/query_input.dart';
import 'package:curiosity/widgets/side_bar.dart';
import 'package:curiosity/widgets/sources_panel.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  static const String _sourcesPanelCollapsedKey = 'sources_panel_collapsed';
  final ScrollController _scrollController = ScrollController();

  String? _highlightTurnId;
  int? _highlightIndex;
  bool _showScrollToBottom = false;
  bool _userScrolledUp = false;
  bool _sourcesPanelCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadSourcesPanelPref();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSourcesPanelPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool(_sourcesPanelCollapsedKey);
      if (val != null && mounted) {
        setState(() => _sourcesPanelCollapsed = val);
      }
    } catch (_) {}
  }

  Future<void> _toggleSourcesPanelCollapsed() async {
    final next = !_sourcesPanelCollapsed;
    setState(() => _sourcesPanelCollapsed = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sourcesPanelCollapsedKey, next);
    } catch (_) {}
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

  void _startNewSearch() {
    ref.read(chatNotifierProvider.notifier).startNewChat();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
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
    if (_sourcesPanelCollapsed) {
      _toggleSourcesPanelCollapsed();
    }
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
        final isMobile = width < 700;
        final isDesktop = width >= 1100;
        final hasSources = activeTurn != null && activeTurn.sources.isNotEmpty;
        final showRightColumn = isDesktop && hasSources;

        return Scaffold(
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: true,
          appBar: isMobile
              ? AppBar(
                  backgroundColor: AppColors.surface,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    tooltip: 'Back',
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomePage()),
                        );
                      }
                    },
                  ),
                  title: Text(
                    activeTurn?.question ?? 'Curiosity',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
                      tooltip: 'New Search',
                      onPressed: _startNewSearch,
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(color: AppColors.border, height: 1),
                  ),
                )
              : null,
          body: Column(
            children: [
              const ConnectionBanner(),
              Expanded(
                child: Row(
                  children: [
                    if (!isMobile) const SideBar(),
                    Expanded(
                      child: _buildConversationBody(
                        turns,
                        activeTurn,
                        showRightColumn,
                        isMobile,
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

  Widget _buildConversationBody(
    List<Turn> turns,
    Turn? activeTurn,
    bool showRightColumn,
    bool isMobile,
  ) {
    final panelWidth = (!showRightColumn || _sourcesPanelCollapsed) ? 0.0 : 340.0;

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
                      final isLive = ref.read(chatNotifierProvider.notifier).isLiveTurn(turn.id);

                      return AnswerView(
                        key: ValueKey(turn.id),
                        turn: turn,
                        isLatest: index == turns.length - 1,
                        animateTypewriter: isLive,
                        showInlineSources: !showRightColumn,
                        highlightedSourceIndex:
                            isHighlightedForTurn ? _highlightIndex : null,
                        onAskQuery: _ask,
                        onHighlightSource: (sIndex) => _highlight(turn.id, sIndex),
                        onRetry: () => _ask(turn.question),
                        onToggleDesktopSources: () {
                          if (showRightColumn) {
                            if (_sourcesPanelCollapsed) {
                              _toggleSourcesPanelCollapsed();
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            // Right column (~340px) collapsible panel for Sources card on desktop >= 1100px
            if (showRightColumn)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: panelWidth,
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: OverflowBox(
                  minWidth: 340,
                  maxWidth: 340,
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: 340,
                    padding: const EdgeInsets.all(16),
                    child: SourcesPanel(
                      sources: activeTurn!.sources,
                      highlightedIndex: _highlightTurnId == activeTurn.id
                          ? _highlightIndex
                          : null,
                      isCollapsible: true,
                      onToggleCollapse: _toggleSourcesPanelCollapsed,
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Re-open sources button when collapsed on desktop
        if (showRightColumn && _sourcesPanelCollapsed)
          Positioned(
            top: 16,
            right: 16,
            child: Tooltip(
              message: 'Show sources',
              child: InkWell(
                onTap: _toggleSourcesPanelCollapsed,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: const Icon(
                    Icons.source_outlined,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        // Floating circular scroll-to-bottom button
        if (_showScrollToBottom)
          Positioned(
            bottom: 110,
            right: (showRightColumn && !_sourcesPanelCollapsed) ? 360 : 28,
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
          right: (showRightColumn && !_sourcesPanelCollapsed) ? 340 : 0,
          bottom: 0,
          child: _buildStickyInputBar(),
        ),
      ],
    );
  }

  Widget _buildStickyInputBar() {
    return SafeArea(
      top: false,
      child: Column(
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
          // Container with QueryInput
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
      ),
    );
  }
}