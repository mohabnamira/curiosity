import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/pages/chat_page.dart';
import 'package:curiosity/providers/chat_provider.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/search_bar_button.dart';

class SearchSection extends ConsumerStatefulWidget {
  const SearchSection({super.key});

  @override
  ConsumerState<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends ConsumerState<SearchSection> {
  final queryController = TextEditingController();

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  void _submit() {
    final query = queryController.text.trim();
    if (query.isEmpty) return;

    ref.read(chatNotifierProvider.notifier).sendQuery(query);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentFocus = ref.watch(chatNotifierProvider.select((s) => s.focus));
    final focusLabel = switch (currentFocus) {
      'academic' => 'Academic',
      'youtube' => 'YouTube',
      _ => 'All',
    };

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Where knowledge begins',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 40,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          width: 700,
          decoration: BoxDecoration(
            color: AppColors.searchBar,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.searchBarBorder, width: 1.5),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: queryController,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Search anything...',
                    hintStyle: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        ref.read(chatNotifierProvider.notifier).setFocus(val);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'all',
                          child: DefaultTextStyle(
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            child: Text('All'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'academic',
                          child: DefaultTextStyle(
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            child: Text('Academic'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'youtube',
                          child: DefaultTextStyle(
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            child: Text('YouTube'),
                          ),
                        ),
                      ],
                      color: AppColors.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SearchBarButton(
                        icon: Icons.auto_awesome_outlined,
                        text: 'Focus: $focusLabel',
                      ),
                    ),
                    const SizedBox(width: 12),
                    const SearchBarButton(
                      icon: Icons.add_circle_outline,
                      text: 'Attach',
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _submit,
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.submitButton,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: AppColors.background,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}