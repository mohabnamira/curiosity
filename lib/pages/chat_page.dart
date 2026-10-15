import 'package:curiosity/providers/chat_provider.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/answer_section.dart';
import 'package:curiosity/widgets/side_bar.dart';
import 'package:curiosity/widgets/sources_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = ref.watch(
      chatNotifierProvider.select((s) => s.activeTurn?.question ?? ''),
    );

    return Scaffold(
      body: Row(
        children: [
          const SideBar(),
          const SizedBox(width: 100),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SourcesSection(),
                    const SizedBox(height: 24),
                    const AnswerSection(),
                  ],
                ),
              ),
            ),
          ),
          const Placeholder(
            strokeWidth: 0,
            color: AppColors.background,
          ),
        ],
      ),
    );
  }
}