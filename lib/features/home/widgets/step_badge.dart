import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StepBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const StepBadge(this.label, this.bg, this.fg, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(label, style: GoogleFonts.firaSansCondensed(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
