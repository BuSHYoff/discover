import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/features/onboarding/widgets/onboarding_models.dart';
import 'package:discover/core/theme/app_theme.dart';

class RelationCard extends StatelessWidget {
  final OnboardingChoice choice;
  final bool             isSelected;
  final VoidCallback     onTap;

  const RelationCard({
    super.key,
    required this.choice,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primary.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.07),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )]
              : [],
        ),
        child: Row(
          children: [
            Icon(choice.icon, size: 26, color: isSelected ? primary : AppColors.inkSoft),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    choice.label,
                    style: GoogleFonts.anton(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? primary : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    choice.subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? primary
                      : Colors.black.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
