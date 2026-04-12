import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/core/theme/app_theme.dart';

class PassionRow extends StatelessWidget {
  final Passion passion;
  final VoidCallback onTap;

  const PassionRow({super.key, required this.passion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10, offset: const Offset(0, 3))],
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
                        const SizedBox(height: 6),
                        Text(
                          passion.tagline.isNotEmpty
                              ? passion.tagline
                              : passion.description.length > 60
                              ? '${passion.description.substring(0, 60)}…'
                              : passion.description,
                          style: GoogleFonts.firaSansCondensed(
                              fontSize: 11,
                              color: AppColors.inkSoft.withValues(alpha: 0.8),
                              height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]),
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
