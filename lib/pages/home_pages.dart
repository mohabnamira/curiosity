import 'package:flutter/material.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/search_section.dart';
import 'package:curiosity/widgets/side_bar.dart';
import 'package:curiosity/services/chat_web_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String fullResponse = '';
  @override
  void initState() {
    super.initState();
    ChatWebService().connect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SideBar(),
          Expanded(
            child: Column(
              children: [
                Expanded(child: const SearchSection()),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "© 2026 curiosity AI, Inc. All rights reserved.",
                          style: TextStyle(
                            color: AppColors.footerGrey,
                            fontSize: 14,
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
      ),
    );
  }
}
