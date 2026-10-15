import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curiosity/services/chat_web_service.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/search_section.dart';
import 'package:curiosity/widgets/side_bar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // The provider is lazy, so read it once here to open the socket at
    // startup instead of on the first search.
    ref.read(chatWebServiceProvider);
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
                const Expanded(child: SearchSection()),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
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