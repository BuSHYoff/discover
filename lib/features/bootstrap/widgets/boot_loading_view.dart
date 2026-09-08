import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:discover/core/theme/app_theme.dart';

/// Écran affiché pendant la séquence de démarrage (init natives + appels API).
///
/// Le backend tourne sur Cloud Run en scale-to-zero : après une période
/// d'inactivité, la première requête doit attendre qu'une instance démarre
/// (~5 s mesurées). Passé [_coldStartHint], on bascule le message pour
/// expliquer l'attente au lieu de laisser un écran figé sans explication.
class BootLoadingView extends StatefulWidget {
  const BootLoadingView({super.key});

  /// Délai au-delà duquel on suppose un démarrage à froid du serveur.
  static const Duration _coldStartHint = Duration(seconds: 3);

  @override
  State<BootLoadingView> createState() => _BootLoadingViewState();
}

class _BootLoadingViewState extends State<BootLoadingView> {
  Timer? _hintTimer;
  bool  _coldStart = false;

  @override
  void initState() {
    super.initState();
    _hintTimer = Timer(BootLoadingView._coldStartHint, () {
      if (mounted) setState(() => _coldStart = true);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = _coldStart
        ? 'Le serveur se réveille, encore un instant…'
        : 'Préparation de votre espace…';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Discover.',
              style: GoogleFonts.dmSans(
                fontSize:      42,
                fontWeight:    FontWeight.w700,
                color:         AppColors.ink,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              height: 22,
              width:  22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:  AlwaysStoppedAnimation(AppColors.green),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Padding(
                key: ValueKey(message),
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color:    AppColors.inkSoft,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
