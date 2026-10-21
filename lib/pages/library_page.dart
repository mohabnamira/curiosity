import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/pages/chat_page.dart';
import 'package:curiosity/providers/chat_provider.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/side_bar.dart';

/// Full library page and reusable view displaying saved conversation history.
class LibraryPage extends ConsumerStatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onStartNewChat;

  const LibraryPage({
    super.key,
    this.isEmbedded = false,
    this.onStartNewChat,
  });

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  late final TextEditingController _filterController;
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _filterController = TextEditingController();
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _onSelectThread(String threadId) {
    ref.read(chatNotifierProvider.notifier).loadThread(threadId);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatPage()),
    );
  }

  Future<void> _renameThread(ChatThread thread) async {
    final controller = TextEditingController(text: thread.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        title: Text(
          'Rename conversation',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Enter conversation title',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(
              'Save',
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && mounted) {
      ref.read(chatNotifierProvider.notifier).renameThread(thread.id, newTitle);
    }
  }

  Future<void> _deleteThread(ChatThread thread) async {
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
          'Are you sure you want to delete "${thread.title}"?',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(chatNotifierProvider.notifier).deleteThread(thread.id);
    }
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        title: Text(
          'Clear all history',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete all saved conversations? This cannot be undone.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Clear All',
              style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(chatNotifierProvider.notifier).clearAllHistory();
    }
  }

  Map<String, List<ChatThread>> _filterAndGroup(List<ChatThread> threads) {
    final filtered = _filterQuery.isEmpty
        ? threads
        : threads.where((t) {
            final q = _filterQuery.toLowerCase();
            return t.title.toLowerCase().contains(q) ||
                t.turns.any((turn) =>
                    turn.question.toLowerCase().contains(q) ||
                    turn.answer.toLowerCase().contains(q));
          }).toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sevenDaysAgo = today.subtract(const Duration(days: 7));

    final groups = <String, List<ChatThread>>{};

    for (final thread in filtered) {
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
        groupKey = '${_monthName(d.month)} ${d.year}'.toUpperCase();
      }

      groups.putIfAbsent(groupKey, () => []).add(thread);
    }

    return groups;
  }

  static String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final threads = ref.watch(chatNotifierProvider.select((s) => s.savedThreads));
    final activeThreadId = ref.watch(chatNotifierProvider.select((s) => s.activeThreadId));
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    final grouped = _filterAndGroup(threads);

    Widget content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          children: [
            // Top action bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, size: 18, color: AppColors.iconMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _filterController,
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search conversations...',
                                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (val) => setState(() => _filterQuery = val.trim()),
                            ),
                          ),
                          if (_filterQuery.isNotEmpty)
                            InkWell(
                              onTap: () {
                                _filterController.clear();
                                setState(() => _filterQuery = '');
                              },
                              child: const Icon(Icons.close_rounded, size: 16, color: AppColors.iconMuted),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (threads.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Tooltip(
                      message: 'Clear all history',
                      child: InkWell(
                        onTap: _confirmClearAll,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: const Icon(
                            Icons.delete_sweep_outlined,
                            size: 19,
                            color: AppColors.iconMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Body list or empty state
            Expanded(
              child: threads.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.auto_stories_outlined,
                      title: 'No conversations yet',
                      subtitle: 'Search anything to start building your library',
                      showNewSearchBtn: true,
                    )
                  : grouped.isEmpty
                      ? _buildEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No matching conversations',
                          subtitle: 'Try searching for something else',
                          showNewSearchBtn: false,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                          itemCount: grouped.length,
                          itemBuilder: (context, gIndex) {
                            final groupKey = grouped.keys.elementAt(gIndex);
                            final groupItems = grouped[groupKey]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                                  child: Text(
                                    groupKey,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                for (final thread in groupItems)
                                  _buildThreadCard(thread, thread.id == activeThreadId),
                              ],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Library',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Row(
        children: [
          if (isDesktop) const SideBar(),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool showNewSearchBtn,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.iconMuted),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            if (showNewSearchBtn) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (widget.onStartNewChat != null) {
                    widget.onStartNewChat!();
                  } else {
                    ref.read(chatNotifierProvider.notifier).startNewChat();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.border, width: 1),
                  ),
                  minimumSize: const Size(140, 44),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'New Search',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThreadCard(ChatThread thread, bool isActive) {
    final turnsCount = thread.turns.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceHover : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? AppColors.focus : AppColors.border,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _onSelectThread(thread.id),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: AppColors.iconMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.title,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$turnsCount ${turnsCount == 1 ? 'question' : 'questions'}',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                color: AppColors.iconMuted,
                tooltip: 'Rename',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () => _renameThread(thread),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                color: AppColors.iconMuted,
                tooltip: 'Delete',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () => _deleteThread(thread),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
