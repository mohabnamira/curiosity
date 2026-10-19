import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/theme/colors.dart';

/// Section header for grouped settings
class SettingSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;

  const SettingSectionHeader({
    super.key,
    required this.title,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.iconMuted),
            const SizedBox(width: 8),
          ],
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

/// A clean setting row container matching the monochrome dark theme
class SettingCard extends StatelessWidget {
  final List<Widget> children;

  const SettingCard({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, thickness: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

/// Single setting row with title, description, and trailing widget (switch, dropdown, value)
class SettingTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Setting row with a continuous or discrete slider
class SettingSliderTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  const SettingSliderTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                valueLabel,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.focus,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.focus,
              overlayColor: Colors.white.withValues(alpha: 0.1),
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
