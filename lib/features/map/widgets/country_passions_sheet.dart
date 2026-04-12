import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/features/home/screens/detail_screen.dart';
import 'package:discover/features/map/widgets/sheet_header.dart';
import 'package:discover/features/map/widgets/passion_row.dart';
import 'package:discover/core/theme/app_theme.dart';

class CountryPassionsSheet extends StatefulWidget {
  final String countryName;
  final String countryCode;
  final List<Passion> passions;
  final bool isExploreMode;

  const CountryPassionsSheet({
    super.key,
    required this.countryName,
    required this.countryCode,
    required this.passions,
    required this.isExploreMode,
  });

  @override
  State<CountryPassionsSheet> createState() => _CountryPassionsSheetState();
}

class _CountryPassionsSheetState extends State<CountryPassionsSheet> {

  String? _activeCategory;

  List<Passion> get _filtered => _activeCategory == null
      ? widget.passions
      : widget.passions.where((p) => p.category == _activeCategory).toList();

  List<String> get _categories => widget.passions
      .map((p) => p.category)
      .toSet()
      .where((c) => c.isNotEmpty)
      .toList()
    ..sort();

  Widget _buildEmptyState(double bottomPadding) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(32, 8, 32, bottomPadding + 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.explore_off_rounded, color: primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune autre activité\ndans ce pays pour l\'instant',
            textAlign: TextAlign.center,
            style: GoogleFonts.firaSansCondensed(
                fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            'D\'autres passions de ${widget.countryName}\narriveront bientôt.',
            textAlign: TextAlign.center,
            style: GoogleFonts.firaSansCondensed(
                fontSize: 13, color: AppColors.inkSoft, height: 1.5),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final filtered      = _filtered;
    final isEmpty       = widget.passions.isEmpty;

    return DraggableScrollableSheet(
      initialChildSize: isEmpty ? 0.38 : 0.55,
      minChildSize: 0.28,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollCtrl) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          color: AppColors.cream,
          child: Column(
            children: [
              // ── Header fixe (toujours visible) ─────────────────────
              SheetHeader(
                isEmpty: isEmpty,
                countryName: widget.countryName,
                countryCode: widget.countryCode,
                filteredCount: filtered.length,
                categories: _categories,
                activeCategory: _activeCategory,
                isExploreMode: widget.isExploreMode,
                onClose: () => Navigator.of(context).pop(),
                onCategoryChanged: (cat) =>
                    setState(() => _activeCategory = cat),
              ),

              // ── Contenu scrollable ─────────────────────────────────
              Expanded(
                child: isEmpty
                    ? _buildEmptyState(bottomPadding)
                    : ListView.separated(
                  controller: scrollCtrl,
                  padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => PassionRow(
                    passion: filtered[i],
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => DetailScreen(passion: filtered[i]),
                      ));
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
