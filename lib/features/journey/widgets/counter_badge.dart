import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

class CounterBadge extends StatelessWidget {
  final int done;
  final int total;
  final String label;

  const CounterBadge({
    super.key,
    required this.done,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(100)),
      child: Text('$done / $total $label', style: GoogleFonts.firaSansCondensed(
          fontSize: 12, fontWeight: FontWeight.w600, color: primary)),
    );
  }
}
