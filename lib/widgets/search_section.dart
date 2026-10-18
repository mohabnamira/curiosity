import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/pages/chat_page.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/query_input.dart';

class SearchSection extends StatelessWidget {
  const SearchSection({super.key});

  void _onSubmit(BuildContext context, String query) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.auto_awesome,
                  size: 40,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'What are you curious about?',
              style: GoogleFonts.newsreader(
                fontSize: 38,
                fontWeight: FontWeight.normal,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: QueryInput(
                hintText: 'Ask anything...',
                autofocus: true,
                onSubmit: (query) => _onSubmit(context, query),
              ),
            ),
          ],
        ),
      ),
    );
  }
}