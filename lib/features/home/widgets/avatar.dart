import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Avatar extends StatelessWidget {
  final String initials;
  final String colorHex;
  final double size;

  const Avatar({
    super.key,
    required this.initials,
    required this.colorHex,
    required this.size,
  });

  Color _parseHex(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final bg = _parseHex(colorHex);
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: bg.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.firaSansCondensed(
            fontSize: size * 0.32,
            fontWeight: FontWeight.w700,
            color: bg,
          ),
        ),
      ),
    );
  }
}
