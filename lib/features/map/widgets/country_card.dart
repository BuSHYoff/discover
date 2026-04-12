import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_flags/country_flags.dart';
import 'package:discover/features/map/widgets/passion_count_badge.dart';
import 'package:discover/core/theme/app_theme.dart';

class CountryCard extends StatelessWidget {
  final String countryCode;
  final String countryName;
  final int passionCount;
  final VoidCallback onLearnMore;

  // Même rayon que la bottom bar (voir _DraggableBar dans main_shell.dart)
  static const double _radius = 28.0;

  const CountryCard({
    super.key,
    required this.countryCode,
    required this.countryName,
    required this.passionCount,
    required this.onLearnMore,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onLearnMore,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Drapeau : même hauteur que la card, largeur fixe ────
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(_radius),
                    bottomLeft: Radius.circular(_radius),
                  ),
                  child: SizedBox(
                    width: 80,
                    height: 72,
                    child: CountryFlag.fromCountryCode(
                      countryCode,
                      theme: const ImageTheme(width: 80, height: 72),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // ── Infos ───────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        countryName,
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: primary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 5),
                      PassionCountBadge(count: passionCount),
                    ],
                  ),
                ),

                // ── Chevron vert ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: primary,
                    size: 28,
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
