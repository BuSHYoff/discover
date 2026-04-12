import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

class SectionLabel extends StatelessWidget {
  final IconData? icon;
  final String label;

  const SectionLabel({super.key, this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppColors.inkSoft),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: GoogleFonts.anton(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
