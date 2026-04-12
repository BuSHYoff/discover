import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

class CheckItem extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;

  const CheckItem({
    super.key,
    required this.label,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: checked ? primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: checked
              ? primary.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.07)),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: checked ? 0.0 : 0.03),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: checked ? primary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                  color: checked ? primary : Colors.black.withValues(alpha: 0.15),
                  width: 1.5),
            ),
            child: checked
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.firaSansCondensed(
              fontSize: 13.5,
              color: checked ? primary : AppColors.ink,
              fontWeight: checked ? FontWeight.w500 : FontWeight.w400,
              decoration: checked ? TextDecoration.lineThrough : null,
              decorationColor: primary.withValues(alpha: 0.4)))),
        ]),
      ),
    );
  }
}
