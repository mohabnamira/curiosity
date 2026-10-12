import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/answer_section.dart';
import 'package:curiosity/widgets/side_bar.dart';
import 'package:curiosity/widgets/sources_section.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  final String question;

  const ChatPage({
    super.key,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideBar(),
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
                    SourcesSection(),
                    const SizedBox(height: 24),
                    AnswerSection(),
                  ],
                ),
              ),
            ),
          ),
          Placeholder(
            strokeWidth: 0,
            color: AppColors.background,
          )
        ],
      ),
    );
  }
}