import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GLISSE HINT — petit indicateur "Glisse pour découvrir" + chevron animé.
// Utilisé par PassionCard (page d'accueil) et ShortsPlayerScreen.
// L'animation de bounce est interne pour pouvoir réutiliser le widget
// sans avoir à propager un AnimationController depuis l'extérieur.
// ─────────────────────────────────────────────────────────────────────────────

class GlisseHint extends StatefulWidget {
  /// Couleur du texte + chevron. Par défaut : blanc semi-transparent (fond sombre).
  final Color? color;
  /// Taille du texte.
  final double textSize;
  /// Taille du chevron.
  final double iconSize;
  /// Texte affiché.
  final String label;

  const GlisseHint({
    super.key,
    this.color,
    this.textSize = 11,
    this.iconSize = 20,
    this.label    = 'Glisse pour découvrir',
  });

  @override
  State<GlisseHint> createState() => _GlisseHintState();
}

class _GlisseHintState extends State<GlisseHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    // Petite oscillation 0 → 6 px vers le bas
    _anim = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Colors.white.withValues(alpha: 0.6);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.firaSansCondensed(
            fontSize: widget.textSize,
            color:    color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _anim.value),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: color,
              size: widget.iconSize,
            ),
          ),
        ),
      ],
    );
  }
}
