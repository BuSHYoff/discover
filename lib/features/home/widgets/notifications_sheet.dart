import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

class NotificationsSheet extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const NotificationsSheet({super.key, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        color: AppColors.cream,
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100))),
          const SizedBox(height: 24),
          Container(width: 56, height: 56,
              decoration: BoxDecoration(color: enabled ? primary : primaryLight, shape: BoxShape.circle),
              child: Icon(enabled ? Icons.notifications_rounded : Icons.notifications_outlined, color: enabled ? Colors.white : primary, size: 26)),
          const SizedBox(height: 16),
          Text('Rappels hebdomadaires', style: GoogleFonts.firaSansCondensed(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text('Reçois un rappel chaque semaines pour maintenir ta pratique et progresser régulièrement.',
              style: GoogleFonts.firaSansCondensed(fontSize: 14, color: AppColors.inkSoft, height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => onChanged(true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: enabled ? primary.withValues(alpha: 0.1) : primary,
                borderRadius: BorderRadius.circular(16),
                border: enabled ? Border.all(color: primary.withValues(alpha: 0.3)) : null,
                boxShadow: enabled ? [] : [BoxShadow(color: primary.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.notifications_rounded, color: enabled ? primary : Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Activer les rappels', style: GoogleFonts.firaSansCondensed(fontSize: 15, fontWeight: FontWeight.w700, color: enabled ? primary : Colors.white)),
                if (enabled) ...[const SizedBox(width: 6), Icon(Icons.check_rounded, color: primary, size: 16)],
              ]),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => onChanged(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: !enabled ? Colors.black.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: !enabled ? Colors.black.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.07)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.notifications_off_outlined, color: !enabled ? AppColors.ink : AppColors.inkSoft, size: 18),
                const SizedBox(width: 8),
                Text('Ne pas me rappeler', style: GoogleFonts.firaSansCondensed(fontSize: 15, fontWeight: FontWeight.w600, color: !enabled ? AppColors.ink : AppColors.inkSoft)),
                if (!enabled) ...[const SizedBox(width: 6), Icon(Icons.check_rounded, color: AppColors.ink, size: 16)],
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
