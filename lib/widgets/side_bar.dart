import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curiosity/pages/chat_page.dart';
import 'package:curiosity/pages/home_pages.dart';
import 'package:curiosity/providers/chat_provider.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/side_bar_button.dart';

class SideBar extends ConsumerStatefulWidget {
  const SideBar({super.key});

  @override
  ConsumerState<SideBar> createState() => _SideBarState();
}

class _SideBarState extends ConsumerState<SideBar> {
  bool isCollapsed = true;

  void _showLibraryDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final chatState = ref.watch(chatNotifierProvider);
            final threads = chatState.savedThreads;

            return Container(
              padding: const EdgeInsets.all(24),
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Library - Saved Conversations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (threads.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No saved conversations yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: threads.length,
                        itemBuilder: (context, index) {
                          final thread = threads[index];
                          final isSelected = chatState.activeThreadId == thread.id;
                          return ListTile(
                            title: Text(
                              thread.title,
                              style: TextStyle(
                                color: isSelected ? Colors.blue.shade400 : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${thread.turns.length} turn(s)',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
                              onPressed: () {
                                ref.read(chatNotifierProvider.notifier).deleteThread(thread.id);
                              },
                            ),
                            onTap: () {
                              ref.read(chatNotifierProvider.notifier).loadThread(thread.id);
                              Navigator.pop(context);
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ChatPage()),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: isCollapsed ? 64 : 128,
      color: AppColors.sideNav,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 17),
            child: Icon(
              Icons.auto_awesome_mosaic,
              color: AppColors.whiteColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              ref.read(chatNotifierProvider.notifier).startNewChat();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
              );
            },
            child: SideBarButton(isCollapsed: isCollapsed, icon: Icons.add, text: 'Home'),
          ),
          SideBarButton(isCollapsed: isCollapsed, icon: Icons.search, text: 'Search'),
          SideBarButton(isCollapsed: isCollapsed, icon: Icons.language, text: 'Space'),
          SideBarButton(isCollapsed: isCollapsed, icon: Icons.auto_awesome, text: 'Discover'),
          GestureDetector(
            onTap: () => _showLibraryDialog(context),
            child: SideBarButton(isCollapsed: isCollapsed, icon: Icons.cloud_outlined, text: 'Library'),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                isCollapsed = !isCollapsed;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              child: Icon(
                isCollapsed
                    ? Icons.keyboard_arrow_right
                    : Icons.keyboard_arrow_left,
                color: AppColors.iconGrey,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}