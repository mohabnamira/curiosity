import 'package:flutter/material.dart';
import 'package:perplexity/theme/colors.dart';
import 'package:perplexity/widgets/side_bar_button.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  bool isCollapsed = true;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: isCollapsed ? 64 : 128,
      color: AppColors.sideNav,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 17),
            child: Icon(
              Icons.auto_awesome_mosaic,
              color: AppColors.whiteColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 24),
          SideBarButton(isCollapsed: isCollapsed, icon: Icons.add, text: 'Home'),
          SideBarButton(isCollapsed: isCollapsed, icon: Icons.search, text: 'Search'),
          SideBarButton(isCollapsed: isCollapsed, icon: Icons.language, text: 'Space'),
          SideBarButton(isCollapsed: isCollapsed, icon: Icons.auto_awesome, text: 'Discover'),
          SideBarButton(isCollapsed: isCollapsed, icon: Icons.cloud_outlined, text: 'Library'),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                isCollapsed = !isCollapsed;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              child: Icon(
                isCollapsed
                    ? Icons.keyboard_arrow_right
                    : Icons.keyboard_arrow_left,
                color: AppColors.iconGrey,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
