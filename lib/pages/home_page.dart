import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/pages/library_page.dart';
import 'package:curiosity/pages/settings_page.dart';
import 'package:curiosity/services/chat_web_service.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/connection_banner.dart';
import 'package:curiosity/widgets/search_section.dart';
import 'package:curiosity/widgets/side_bar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedMobileIndex = 0;

  @override
  void initState() {
    super.initState();
    // Eagerly initialize WebSocket on app startup
    ref.read(chatWebServiceProvider);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        if (isMobile) {
          return Scaffold(
            backgroundColor: AppColors.background,
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: Column(
                children: [
                  const ConnectionBanner(),
                  Expanded(
                    child: switch (_selectedMobileIndex) {
                      1 => LibraryPage(
                          isEmbedded: true,
                          onStartNewChat: () => setState(() => _selectedMobileIndex = 0),
                        ),
                      2 => const SettingsPage(isEmbedded: true),
                      _ => const SearchSection(),
                    },
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _buildFloatingBottomNav(),
          );
        }

        // Desktop / Tablet layout (>= 700px)
        return Scaffold(
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: true,
          body: Row(
            children: [
              const SideBar(),
              Expanded(
                child: Column(
                  children: [
                    const ConnectionBanner(),
                    const Expanded(
                      child: SearchSection(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildFloatingBottomNav() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFF1E2129),
            borderRadius: BorderRadius.circular(31),
            border: Border.all(
              color: const Color(0xFF2E323D),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.search_rounded,
                selectedIcon: Icons.search_rounded,
                label: 'Home',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.folder_outlined,
                selectedIcon: Icons.folder_rounded,
                label: 'Library',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings_rounded,
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = _selectedMobileIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedMobileIndex = index),
          borderRadius: BorderRadius.circular(25),
          splashColor: Colors.white.withValues(alpha: 0.05),
          highlightColor: Colors.white.withValues(alpha: 0.03),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2A2E39) : Colors.transparent,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 20,
                  color: isSelected ? AppColors.textPrimary : AppColors.iconMuted,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.textPrimary : AppColors.iconMuted,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}