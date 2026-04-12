import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_flags/country_flags.dart';
import 'package:discover/features/map/widgets/passion_count_badge.dart';
import 'package:discover/features/map/widgets/filter_chip.dart';
import 'package:discover/core/theme/app_theme.dart';

class SheetHeader extends StatelessWidget {
  final bool isEmpty;
  final String countryName;
  final String countryCode;
  final int filteredCount;
  final List<String> categories;
  final String? activeCategory;
  final bool isExploreMode;
  final VoidCallback onClose;
  final ValueChanged<String?> onCategoryChanged;

  const SheetHeader({
    super.key,
    required this.isEmpty,
    required this.countryName,
    required this.countryCode,
    required this.filteredCount,
    required this.categories,
    required this.activeCategory,
    required this.isExploreMode,
    required this.onClose,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = !isEmpty && categories.length > 1;
    return Container(
      color: AppColors.cream,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            // ── Mode explore : drapeau + nom + badge ──────────────
            if (isExploreMode) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CountryFlag.fromCountryCode(
                  countryCode,
                  theme: const ImageTheme(width: 36, height: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      countryName,
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    PassionCountBadge(count: filteredCount),
                  ],
                ),
              ),
            ] else ...[
              // ── Mode détail : titre texte ──────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEmpty ? 'Aucune autre activité' : 'Aussi dans ce pays',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    Text(
                      isEmpty
                          ? countryName
                          : '$filteredCount activité${filteredCount > 1 ? 's' : ''} · $countryName',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 12, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
            GestureDetector(
              onTap: onClose,
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: AppColors.inkSoft),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        if (hasFilters) ...[
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                MapFilterChip(
                  label: 'Tous',
                  active: activeCategory == null,
                  onTap: () => onCategoryChanged(null),
                ),
                const SizedBox(width: 8),
                ...categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: MapFilterChip(
                    label: cat,
                    active: activeCategory == cat,
                    onTap: () => onCategoryChanged(
                        activeCategory == cat ? null : cat),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ]),
    );
  }
}
