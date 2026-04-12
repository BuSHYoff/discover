import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

class Page4 extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final ValueChanged<String>  onChanged;

  const Page4({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Et toi,\nc\'est comment ?',
            style: GoogleFonts.anton(
              fontSize: 34,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Donne ton meilleur pseudo, ça sera visible par tout le monde.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 48),

          // ── Champ prénom ──
          TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.anton(
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              hintText: 'Ton prénom',
              hintStyle: GoogleFonts.anton(
                fontSize: 32,
                fontWeight: FontWeight.w400,
                color: AppColors.inkFaint,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.ink.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            cursorColor: Theme.of(context).colorScheme.primary,
          ),

          const SizedBox(height: 32),

          // Message de bienvenue dynamique
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: controller.text.trim().isNotEmpty
                ? Builder(builder: (context) {
                    final primary = Theme.of(context).colorScheme.primary;
                    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
                    return Container(
                      key: const ValueKey('welcome'),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Bienvenue ${controller.text.trim()} — '
                            'Tu es prêt à Discover ?',
                        style: GoogleFonts.anton(
                          fontSize: 14,
                          color: primary,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    );
                  })
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ],
      ),
    );
  }
}

