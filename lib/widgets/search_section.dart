import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:curiosity/pages/chat_page.dart';
import 'package:curiosity/providers/chat_provider.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/search_bar_button.dart';
import 'package:curiosity/widgets/answer_section.dart';

class SearchSection extends ConsumerStatefulWidget {
  const SearchSection({super.key});

  @override
  ConsumerState<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends ConsumerState<SearchSection> {
  final queryController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  void _submit() {
    final query = queryController.text.trim();
    if (query.isEmpty) return;


    ref.read(ttsServiceProvider).stop();

    ref.read(chatNotifierProvider.notifier).sendQuery(query);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatPage()),
    );
  }

  Future<void> _listen() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice input is not supported on Flutter Web in this environment.'),
        ),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    try {
      bool available = await _speech.initialize(
        onError: (_) {
          setState(() => _isListening = false);
        },
        onStatus: (val) {
          if (val == 'notListening' || val == 'done') {
            setState(() => _isListening = false);
          }
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              queryController.text = val.recognizedWords;
            });
          },
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available or permission denied.'),
          ),
        );
        setState(() => _isListening = false);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not supported on this platform.'),
        ),
      );
      setState(() => _isListening = false);
    }
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
                    hintText: _isListening ? 'Listening...' : 'Search anything...',
                    hintStyle: TextStyle(
                      color: _isListening ? Colors.redAccent : AppColors.textGrey,
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
                        side: BorderSide(color: Colors.grey.shade800),
                      ),
                      child: SearchBarButton(
                        icon: Icons.auto_awesome_outlined,
                        text: 'Focus: $focusLabel',
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _listen,
                      child: SearchBarButton(
                        icon: _isListening ? Icons.mic : Icons.mic_none,
                        text: _isListening ? 'Listening' : 'Voice',
                      ),
                    ),
                    const SizedBox(width: 12),
                    SearchBarButton(
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