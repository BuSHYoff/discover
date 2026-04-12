import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

class DetailLegend extends StatelessWidget {
  final String countryName;

  const DetailLegend({super.key, required this.countryName});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryLight.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
              color: primary, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Cette activité est originaire de $countryName',
            style: GoogleFonts.firaSansCondensed(
                fontSize: 13,
                color: primary,
                fontWeight: FontWeight.w500,
                height: 1.4),
          ),
        ),
      ]),
    );
  }
}
