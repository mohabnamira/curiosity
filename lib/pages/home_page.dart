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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: isMobile
              ? const Drawer(
                  backgroundColor: AppColors.surface,
                  child: SideBar(isDrawer: true),
                )
              : null,
          appBar: isMobile
              ? AppBar(
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: AppColors.textPrimary),
                )
              : null,
          body: Row(
            children: [
              if (!isMobile) const SideBar(),
              const Expanded(
                child: SearchSection(),
              ),
            ],
          ),
        );
      },
    );
  }
}