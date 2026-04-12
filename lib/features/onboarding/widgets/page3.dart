import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/features/onboarding/widgets/onboarding_models.dart';
import 'package:discover/features/onboarding/widgets/section_label.dart';
import 'package:discover/features/onboarding/widgets/compact_choice.dart';
import 'package:discover/core/theme/app_theme.dart';

class Page3 extends StatelessWidget {
  final String                   selectedTime;
  final String                   selectedBudget;
  final List<OnboardingChoice>   timeChoices;
  final List<OnboardingChoice>   budgetChoices;
  final ValueChanged<String>     onSelectTime;
  final ValueChanged<String>     onSelectBudget;

  const Page3({
    super.key,
    required this.selectedTime,
    required this.selectedBudget,
    required this.timeChoices,
    required this.budgetChoices,
    required this.onSelectTime,
    required this.onSelectBudget,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tes contraintes\nréelles ?',
            style: GoogleFonts.anton(
              fontSize: 34,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'On adapte les suggestions à ta réalité.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 32),

          // ── Temps par week ──
          SectionLabel(
            icon: Icons.timer_outlined,
            label: 'Temps dispo par semaine',
          ),
          const SizedBox(height: 12),
          ...timeChoices.map((c) => CompactChoice(
            choice: c,
            isSelected: selectedTime == c.label,
            onTap: () => onSelectTime(c.label),
          )),

          const SizedBox(height: 28),

          // ── Budget ──
          SectionLabel(
            icon: Icons.payments_outlined,
            label: 'Budget pour démarrer',
          ),
          const SizedBox(height: 12),
          ...budgetChoices.map((c) => CompactChoice(
            choice: c,
            isSelected: selectedBudget == c.label,
            onTap: () => onSelectBudget(c.label),
          )),
        ],
      ),
    );
  }
}
