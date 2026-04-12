import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatPill extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final Color bgColor;

  const StatPill({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Text('$value',
              style: GoogleFonts.firaSansCondensed(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1.1)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.firaSansCondensed(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.7))),
        ]),
      ),
    );
  }
}
