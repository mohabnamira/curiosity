import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/providers/chat_provider.dart';
import 'package:curiosity/theme/colors.dart';

class AnswerSection extends ConsumerWidget {
  const AnswerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turn = ref.watch(chatNotifierProvider.select((s) => s.activeTurn));
    final answer = turn?.answer ?? '';
    final status = turn?.status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Curiosity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (answer.isNotEmpty)
          MarkdownBody(
            data: answer,
            styleSheet: MarkdownStyleSheet(
              codeblockDecoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              code: const TextStyle(fontSize: 16),
            ),
          )
        else if (turn != null && turn.isInFlight)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
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
                  'Generating answer...',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          )
        else if (status == TurnStatus.done)
          const Text(
            'No answer was generated.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        if (status == TurnStatus.error)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              'Error: ${turn?.errorMessage ?? "Failed to generate answer"}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ),
      ],
    );
  }
}