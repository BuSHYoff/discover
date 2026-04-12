import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/features/journey/widgets/step_shell.dart';
import 'package:discover/features/home/screens/community_screen.dart';
import 'package:discover/core/theme/app_theme.dart';

class ShareStep extends StatelessWidget {
  final Passion passion;

  const ShareStep({super.key, required this.passion});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
    return StepShell(
      icon: Icons.diversity_3_rounded,
      title: 'La communauté',
      subtitle: 'Rejoins des passionnés comme toi, partage tes créations et découvre celles des autres.',
      body: Column(children: [
        // Bouton principal : Voir les créations
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CommunityScreen(passion: passion),
            ));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary, primary],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Voir les créations',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 3),
                  Text('Photos, likes & commentaires',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75))),
                ]),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.white.withValues(alpha: 0.6)),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Bouton secondaire : Partager une création
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CommunityScreen(passion: passion),
            ));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: primary.withValues(alpha: 0.2)),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.add_a_photo_outlined,
                    color: primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Partager ma création',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text('Montre ta progression à la communauté',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 12, color: AppColors.inkSoft)),
                ]),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: AppColors.ink.withValues(alpha: 0.3)),
            ]),
          ),
        ),
      ]),
    );
  }
}
