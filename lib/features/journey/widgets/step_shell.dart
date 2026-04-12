import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

class StepShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget body;
  final Widget? badge;

  const StepShell({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
              color: primaryLight, borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: primary, size: 26),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: GoogleFonts.firaSansCondensed(
                fontSize: 26, fontWeight: FontWeight.w700,
                color: AppColors.ink, height: 1.1)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: GoogleFonts.firaSansCondensed(
                fontSize: 14, color: AppColors.inkSoft, height: 1.55)),
        if (badge != null) ...[const SizedBox(height: 12), badge!],
        const SizedBox(height: 22),
        body,
      ]),
    );
  }
}
