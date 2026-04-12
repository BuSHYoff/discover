import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/features/journey/widgets/journey_progress.dart';
import 'package:discover/features/profile/screens/profile_screen.dart';
import 'package:discover/core/theme/app_theme.dart';

class PassionRow extends StatelessWidget {
  final Passion passion;
  final VoidCallback onTap;

  const PassionRow({super.key, required this.passion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = JourneyProgress.of(passion.id).globalPercent;
    final pt  = ProfileTheme.fromHex(ProfileData.instance.profileColorHex);

    final String statusLabel;
    final Color  statusColor;
    final Color  statusBg;
    final IconData statusIcon;

    if (pct >= 1.0) {
      statusLabel = 'Terminée';
      statusColor = const Color(0xFF7B5EA7);
      statusBg    = const Color(0xFFF0EBFB);
      statusIcon  = Icons.check_circle_outline_rounded;
    } else if (pct > 0.0) {
      statusLabel = 'En cours · ${(pct * 100).round()}%';
      statusColor = pt.primary;
      statusBg    = pt.light;
      statusIcon  = Icons.access_time;
    } else {
      statusLabel = 'Découverte';
      statusColor = const Color(0xFFA0522D);
      statusBg    = const Color(0xFFFBF0E8);
      statusIcon  = Icons.explore_outlined;
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Image — s'étire sur toute la hauteur de la card
              SizedBox(
                width: 88,
                child: Image.network(
                  passion.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.greenLight),
                ),
              ),
              const SizedBox(width: 14),
              // Infos
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(passion.name,
                          style: GoogleFonts.firaSansCondensed(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink)),
                      const SizedBox(height: 3),
                      Text(passion.category,
                          style: GoogleFonts.firaSansCondensed(
                              fontSize: 11.5, color: AppColors.inkSoft)),
                      const SizedBox(height: 8),
                      // Barre de progression si en cours
                      if (pct > 0.0 && pct < 1.0) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            height: 3,
                            color: pt.primary.withValues(alpha: 0.12),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: pct,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: pt.primary,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      // Badge statut
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(statusIcon, size: 10, color: statusColor),
                          const SizedBox(width: 4),
                          Text(statusLabel,
                              style: GoogleFonts.firaSansCondensed(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor)),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: AppColors.inkSoft.withValues(alpha: 0.4)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
