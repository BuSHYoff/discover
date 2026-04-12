import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/features/onboarding/widgets/onboarding_models.dart';
import 'package:discover/features/onboarding/widgets/relation_card.dart';
import 'package:discover/core/theme/app_theme.dart';

class Page1 extends StatelessWidget {
  final String                   selected;
  final List<OnboardingChoice>   choices;
  final ValueChanged<String>     onSelect;

  const Page1({
    super.key,
    required this.selected,
    required this.choices,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ton rapport\naux hobbies ?',
            style: GoogleFonts.anton(
              fontSize: 34,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pour mieux comprendre d\'où tu pars.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 36),
          ...choices.map((c) => RelationCard(
            choice: c,
            isSelected: selected == c.label,
            onTap: () => onSelect(c.label),
          )),
        ],
      ),
    );
  }
}
