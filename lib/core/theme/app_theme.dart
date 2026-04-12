import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── COULEURS STATIQUES ───────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // ─── Fond & textes ─────────────────────────────────────────────────────────
  static const Color cream      = Color(0xFFFAF9F7);
  static const Color ink        = Color(0xFF1A1A1A);
  static const Color inkSoft    = Color(0xFF6B6B6B);
  static const Color inkFaint   = Color(0xFFAEAEAD);

  // ─── Vert défaut (fallback si ProfileData pas encore chargé) ───────────────
  static const Color green      = Color(0xFF2D5A3D);
  static const Color greenLight = Color(0xFFEBF2ED);
  static const Color greenMid   = Color(0xFF3D7A52);
  static const Color greenDark  = Color(0xFF2D3A30);

  // ─── Erreur ────────────────────────────────────────────────────────────────
  static const Color error      = Color(0xFFE53935);
  static const Color errorSoft  = Color(0xFFE57373);
  static const Color errorDark  = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEEEE);
  static const Color errorPale  = Color(0xFFFFCDD2);

  // ─── Gris ──────────────────────────────────────────────────────────────────
  static const Color grey       = Color(0xFFBCC8D0);
  static const Color greyLight  = Color(0xFFD4DDE2);
}

// ─── PALETTE DYNAMIQUE (dérivée de la couleur de profil) ─────────────────────

class ProfileTheme {
  final Color primary; // couleur brand
  final Color light;   // fond très clair (82 % blanc)
  final Color mid;     // teinte intermédiaire (50 % blanc)
  final Color dark;    // version foncée (–10 % lightness)

  const ProfileTheme._({
    required this.primary,
    required this.light,
    required this.mid,
    required this.dark,
  });

  factory ProfileTheme.fromHex(String hex) {
    final color = hexToColor(hex);
    final hsl   = HSLColor.fromColor(color);
    final dark  = hsl
        .withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0))
        .toColor();
    return ProfileTheme._(
      primary: color,
      light:   Color.lerp(color, Colors.white, 0.82)!,
      mid:     Color.lerp(color, Colors.white, 0.50)!,
      dark:    dark,
    );
  }

  /// Ombre portée avec opacité
  Color shadow(double alpha) => primary.withValues(alpha: alpha);

  /// Convertit un hex (#RRGGBB) en Color
  static Color hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ─── THÈME MATERIAL ───────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  /// Thème statique par défaut (vert)
  static ThemeData get theme => fromHex('#2D5A3D');

  /// Thème généré depuis la couleur de profil choisie
  static ThemeData fromHex(String hex) {
    final pt = ProfileTheme.fromHex(hex);
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: pt.primary,
        surface: AppColors.cream,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: GoogleFonts.dmSansTextTheme(),
      useMaterial3: true,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: pt.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pt.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: pt.primary),
      ),
    );
  }
}
