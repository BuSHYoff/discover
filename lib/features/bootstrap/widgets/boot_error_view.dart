import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:discover/core/theme/app_theme.dart';

/// Écran affiché quand la séquence de démarrage a échoué malgré les retries.
///
/// Remplace l'ancien comportement — une exception non rattrapée dans `main()`
/// empêchait `runApp()` de s'exécuter, laissant un écran vide sans issue.
class BootErrorView extends StatelessWidget {
  final String    message;
  final Future<void> Function() onRetry;

  const BootErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 48, color: AppColors.inkFaint),
              const SizedBox(height: 24),
              Text(
                'Connexion impossible',
                style: GoogleFonts.dmSans(
                  fontSize:   22,
                  fontWeight: FontWeight.w700,
                  color:      AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  height:   1.5,
                  color:    AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
