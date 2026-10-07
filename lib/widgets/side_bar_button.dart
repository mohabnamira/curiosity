import 'package:flutter/material.dart';
import 'package:curiosity/theme/colors.dart';

class SideBarButton extends StatelessWidget {
  final bool isCollapsed;
  final IconData icon;
  final String text;

  const SideBarButton({
    super.key,
    required this.text,
    required this.icon,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 21),
          child: Icon( icon, color: AppColors.iconGrey, size: 22),
        ),
        isCollapsed
            ? const SizedBox()
            : Text(
                text,
                style: TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ],
    );
  }
}
