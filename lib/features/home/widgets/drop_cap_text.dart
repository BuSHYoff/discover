import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

class DropCapText extends StatelessWidget {
  final String text;

  const DropCapText({super.key, required this.text});

  (String, String) _splitFirstSentence(String text) {
    final match = RegExp(r'^(.+?[.!?])\s+(.+)$', dotAll: true).firstMatch(text);
    if (match != null) return (match.group(1)!, match.group(2)!);
    return (text, '');
  }

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final primary = Theme.of(context).colorScheme.primary;
    final (firstSentence, rest) = _splitFirstSentence(text);
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(width: 3, margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(100))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('À PROPOS', style: GoogleFonts.firaSansCondensed(fontSize: 10, fontWeight: FontWeight.w600, color: primary, letterSpacing: 1.4)),
          const SizedBox(height: 6),
          Text(firstSentence, style: GoogleFonts.firaSansCondensed(fontSize: 16, height: 1.6, color: AppColors.ink, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic)),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(rest, style: GoogleFonts.firaSansCondensed(fontSize: 15, height: 1.7, color: AppColors.inkSoft, fontWeight: FontWeight.w300)),
          ],
        ])),
      ]),
    );
  }
}
