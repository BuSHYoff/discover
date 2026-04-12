import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class UniverseData {
  final String name;
  final IconData icon;
  final Color bg;
  final Color fg;
  const UniverseData(this.name, this.icon, this.bg, this.fg);
}

class UniverseCard extends StatelessWidget {
  final UniverseData universe;

  const UniverseCard({super.key, required this.universe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: Container(
        width: 96,
        decoration: BoxDecoration(
          color: universe.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: universe.fg.withValues(alpha: 0.12), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(universe.icon, size: 28, color: universe.fg),
            const SizedBox(height: 6),
            Text(universe.name,
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: universe.fg)),
          ],
        ),
      ),
    );
  }
}
