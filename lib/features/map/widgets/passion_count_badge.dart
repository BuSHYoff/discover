import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

class PassionCountBadge extends StatelessWidget {
  final int count;

  const PassionCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final label = '$count activité${count > 1 ? 's' : ''}';
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // LED verte
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.55),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.firaSansCondensed(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.inkSoft),
        ),
      ],
    );
  }
}
