import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:curiosity/pages/chat_page.dart';
import 'package:curiosity/providers/chat_provider.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/search_bar_button.dart';
import 'package:curiosity/widgets/answer_section.dart' show ttsServiceProvider;

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
    _speech.cancel();
    queryController.dispose();
    super.dispose();
  }

  void _setListening(bool value) {
    if (mounted) setState(() => _isListening = value);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _submit() {
    final query = queryController.text.trim();
    if (query.isEmpty) return;

    _speech.stop();
    ref.read(ttsServiceProvider).stop();

    ref.read(chatNotifierProvider.notifier).sendQuery(query);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatPage()),
    );
  }

  Future<void> _listen() async {
    if (_isListening) {
      await _speech.stop();
      _setListening(false);
      return;
    }

    try {
      final available = await _speech.initialize(
        onError: (_) => _setListening(false),
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            _setListening(false);
          }
        },
      );

      if (!available) {
        _snack('Voice input is unavailable. Allow the microphone, or use Chrome.');
        _setListening(false);
        return;
      }

      _setListening(true);
      _speech.listen(
        onResult: (result) {
          if (mounted) queryController.text = result.recognizedWords;
        },
      );
    } catch (_) {
      _snack('Voice input is not supported here.');
      _setListening(false);
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