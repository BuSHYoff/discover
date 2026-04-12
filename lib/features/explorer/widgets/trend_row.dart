import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/core/services/trending_service.dart';
import 'package:discover/core/theme/app_theme.dart';

export 'package:discover/core/services/trending_service.dart' show TrendItem;

class TrendRow extends StatelessWidget {
  final int       rank;
  final Passion   passion;
  final TrendItem trend;
  final VoidCallback onTap;

  const TrendRow({
    super.key,
    required this.rank,
    required this.passion,
    required this.trend,
    required this.onTap,
  });

  Color get _rankColor {
    switch (rank) {
      case 1:  return const Color(0xFFB8860B);
      case 2:  return const Color(0xFF8A8A8A);
      case 3:  return const Color(0xFF8B4513);
      default: return AppColors.inkSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Rang ────────────────────────────────────────────────────────
            SizedBox(
              width: 28,
              child: Text(
                '#$rank',
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _rankColor),
              ),
            ),
            const SizedBox(width: 10),

            // ── Miniature ───────────────────────────────────────────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.network(
                passion.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: AppColors.greenDark),
              ),
            ),
            const SizedBox(width: 12),

            // ── Nom + catégorie ──────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(passion.name,
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(passion.category,
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 11, color: AppColors.inkSoft)),
                ],
              ),
            ),

            Icon(Icons.chevron_right_rounded,
                color: AppColors.inkSoft.withValues(alpha: 0.4), size: 16),
          ],
        ),
      ),
    );
  }
}
