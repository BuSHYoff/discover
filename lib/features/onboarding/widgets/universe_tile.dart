import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/features/onboarding/widgets/onboarding_models.dart';
import 'package:discover/core/theme/app_theme.dart';

class UniverseTile extends StatelessWidget {
  final OnboardingUniverseChoice choice;
  final bool                    isSelected;
  final bool                    isDisabled;
  final VoidCallback            onTap;

  const UniverseTile({
    super.key,
    required this.choice,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDisabled ? 0.38 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? choice.bgColor : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? choice.textColor.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.07),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(
              color: choice.textColor.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(choice.icon, size: 26, color: isSelected ? choice.textColor : AppColors.inkSoft),
              const SizedBox(height: 6),
              Text(
                choice.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.anton(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? choice.textColor : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
