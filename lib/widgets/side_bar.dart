import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/pages/chat_page.dart';
import 'package:curiosity/pages/home_pages.dart';
import 'package:curiosity/providers/chat_provider.dart';
import 'package:curiosity/theme/colors.dart';

class SideBar extends ConsumerStatefulWidget {
  final bool isDrawer;

  const SideBar({super.key, this.isDrawer = false});

  @override
  ConsumerState<SideBar> createState() => _SideBarState();
}

class _SideBarState extends ConsumerState<SideBar> {
  static const String _collapsedPrefKey = 'sidebar_is_collapsed';
  bool _isCollapsed = false;
  String? _renamingThreadId;
  late final TextEditingController _renameController;
  final FocusNode _renameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController();
    _loadCollapsedPref();
  }

  @override
  void dispose() {
    _renameController.dispose();
    _renameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCollapsedPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_collapsedPrefKey);
      if (saved != null && mounted) {
        setState(() => _isCollapsed = saved);
      }
    } catch (_) {}
  }

  Future<void> _toggleCollapsed() async {
    final next = !_isCollapsed;
    setState(() => _isCollapsed = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_collapsedPrefKey, next);
    } catch (_) {}
  }

  void _onNewThread() {
    ref.read(chatNotifierProvider.notifier).startNewChat();
    if (widget.isDrawer) {
      Navigator.of(context).pop(); // close drawer
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  void _onSelectThread(String threadId) {
    ref.read(chatNotifierProvider.notifier).loadThread(threadId);
    if (widget.isDrawer) {
      Navigator.of(context).pop(); // close drawer
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ChatPage()),
      (route) => route.isFirst,
    );
  }

  void _startRename(ChatThread thread) {
    setState(() {
      _renamingThreadId = thread.id;
      _renameController.text = thread.title;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_renameFocusNode.canRequestFocus) {
        _renameFocusNode.requestFocus();
        _renameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _renameController.text.length,
        );
      }
    });
  }

  void _saveRename(String threadId) {
    final newTitle = _renameController.text.trim();
    if (newTitle.isNotEmpty) {
      ref.read(chatNotifierProvider.notifier).renameThread(threadId, newTitle);
    }
    setState(() => _renamingThreadId = null);
  }

  void _cancelRename() {
    setState(() => _renamingThreadId = null);
  }

  Future<void> _confirmDelete(ChatThread thread) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        title: Text(
          'Delete thread',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this conversation?',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final chatState = ref.read(chatNotifierProvider);
      final wasActive = chatState.activeThreadId == thread.id;
      await ref.read(chatNotifierProvider.notifier).deleteThread(thread.id);
      if (wasActive && mounted) {
        if (widget.isDrawer) {
          Navigator.of(context).pop();
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    }
  }

  Map<String, List<ChatThread>> _groupThreads(List<ChatThread> threads) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sevenDaysAgo = today.subtract(const Duration(days: 7));

    final groups = <String, List<ChatThread>>{};

    for (final thread in threads) {
      final d = thread.updatedAt;
      final threadDate = DateTime(d.year, d.month, d.day);

      String groupKey;
      if (threadDate.isAtSameMomentAs(today) || threadDate.isAfter(today)) {
        groupKey = 'TODAY';
      } else if (threadDate.isAtSameMomentAs(yesterday)) {
        groupKey = 'YESTERDAY';
      } else if (threadDate.isAfter(sevenDaysAgo)) {
        groupKey = 'PREVIOUS 7 DAYS';
      } else {
        final monthName = _monthName(d.month);
        groupKey = '$monthName ${d.year}'.toUpperCase();
      }

      groups.putIfAbsent(groupKey, () => []).add(thread);
    }

    return groups;
  }

  static String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveCollapsed = widget.isDrawer ? false : _isCollapsed;
    final width = effectiveCollapsed ? 64.0 : 260.0;

    final chatState = ref.watch(chatNotifierProvider);
    final activeThreadId = chatState.activeThreadId;
    final groupedThreads = _groupThreads(chatState.savedThreads);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(effectiveCollapsed),
          const SizedBox(height: 12),
          _buildNewThreadButton(effectiveCollapsed),
          const SizedBox(height: 12),
          if (!effectiveCollapsed)
            Expanded(
              child: _buildHistoryList(groupedThreads, activeThreadId),
            )
          else
            const Spacer(),
          if (!widget.isDrawer) _buildFooter(effectiveCollapsed),
        ],
      ),
    );
  }

  Widget _buildHeader(bool collapsed) {
    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 10 : 14),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            collapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.auto_awesome,
                      size: 24,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Curiosity',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!collapsed && !widget.isDrawer)
            IconButton(
              icon: const Icon(Icons.menu_open_rounded, size: 20),
              color: AppColors.iconMuted,
              tooltip: 'Collapse sidebar',
              onPressed: _toggleCollapsed,
            ),
        ],
      ),
    );
  }

  Widget _buildNewThreadButton(bool collapsed) {
    if (collapsed) {
      return Center(
        child: Tooltip(
          message: 'New Thread',
          child: InkWell(
            onTap: _onNewThread,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _NewThreadHoverButton(onTap: _onNewThread),
    );
  }

  Widget _buildHistoryList(
    Map<String, List<ChatThread>> grouped,
    String? activeThreadId,
  ) {
    if (grouped.isEmpty) {
      return Center(
        child: Text(
          'No conversations yet',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
            child: Text(
              entry.key,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          for (final thread in entry.value)
            _buildThreadRow(thread, thread.id == activeThreadId),
        ],
      ],
    );
  }

  Widget _buildThreadRow(ChatThread thread, bool isActive) {
    final isRenaming = _renamingThreadId == thread.id;

    if (isRenaming) {
      return Container(
        height: 36,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.focus, width: 1),
        ),
        alignment: Alignment.center,
        child: TextField(
          controller: _renameController,
          focusNode: _renameFocusNode,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onSubmitted: (_) => _saveRename(thread.id),
          onTapOutside: (_) => _cancelRename(),
        ),
      );
    }

    return _ThreadRowWidget(
      thread: thread,
      isActive: isActive,
      onTap: () => _onSelectThread(thread.id),
      onRename: () => _startRename(thread),
      onDelete: () => _confirmDelete(thread),
    );
  }

  Widget _buildFooter(bool collapsed) {
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            color: AppColors.iconMuted,
            tooltip: 'Expand sidebar',
            onPressed: _toggleCollapsed,
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }
}

class _NewThreadHoverButton extends StatefulWidget {
  final VoidCallback onTap;

  const _NewThreadHoverButton({required this.onTap});

  @override
  State<_NewThreadHoverButton> createState() => _NewThreadHoverButtonState();
}

class _NewThreadHoverButtonState extends State<_NewThreadHoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered ? AppColors.focus : AppColors.border,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(
                Icons.add,
                color: AppColors.textPrimary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'New Thread',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadRowWidget extends StatefulWidget {
  final ChatThread thread;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _ThreadRowWidget({
    required this.thread,
    required this.isActive,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<_ThreadRowWidget> createState() => _ThreadRowWidgetState();
}

class _ThreadRowWidgetState extends State<_ThreadRowWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeBg = const Color(0xFF20232B); // surface highlight

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: () => _showMobileMenu(context),
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? activeBg
                : (_isHovered ? AppColors.surface : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isActive ? AppColors.border : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.thread.title,
                  style: GoogleFonts.inter(
                    color: widget.isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight:
                        widget.isActive ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _isHovered ? 1.0 : 0.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: widget.onRename,
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 15,
                          color: AppColors.iconMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: widget.onDelete,
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 15,
                          color: AppColors.iconMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
              title: Text('Rename', style: GoogleFonts.inter(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.of(ctx).pop();
                widget.onRename();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent)),
              onTap: () {
                Navigator.of(ctx).pop();
                widget.onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}