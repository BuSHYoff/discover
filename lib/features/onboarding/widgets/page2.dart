import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/features/onboarding/widgets/onboarding_models.dart';
import 'package:discover/features/onboarding/widgets/universe_tile.dart';
import 'package:discover/core/theme/app_theme.dart';

class Page2 extends StatelessWidget {
  final List<String>                    selected;
  final List<OnboardingUniverseChoice>   choices;
  final ValueChanged<String>            onToggle;

  const Page2({
    super.key,
    required this.selected,
    required this.choices,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final maxReached = selected.length >= 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quels univers\nt\'attirent ?',
            style: GoogleFonts.anton(
              fontSize: 34,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Choisis ',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w300,
                ),
              ),
              Text(
                'jusqu\'à 3',
                style: GoogleFonts.anton(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' univers.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: choices.map((c) {
              final isSelected = selected.contains(c.label);
              final isDisabled = maxReached && !isSelected;
              return UniverseTile(
                choice: c,
                isSelected: isSelected,
                isDisabled: isDisabled,
                onTap: () => onToggle(c.label),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
