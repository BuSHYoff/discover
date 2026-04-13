import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/features/onboarding/widgets/onboarding_models.dart';
import 'package:discover/core/theme/app_theme.dart';

class CompactChoice extends StatelessWidget {
  final OnboardingChoice choice;
  final bool             isSelected;
  final VoidCallback     onTap;

  const CompactChoice({
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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primary.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.07),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(choice.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                choice.label,
                style: GoogleFonts.anton(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? primary : AppColors.ink,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primary, size: 18),
          ],
        ),
      ),
    );
  }
}
