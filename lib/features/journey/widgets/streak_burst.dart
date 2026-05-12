import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STREAK BURST — overlay plein écran qui apparaît quand le streak augmente.
//
// Layout :
//   - Fondu noir semi-opaque en background (fade in/out)
//   - GIF streak.gif centré avec le nouveau compteur en chiffre au milieu
//   - Texte informatif sous le gif pour motiver à revenir demain
//
// Auto-dismiss après 2.5s OU tap sur l'écran.
// ─────────────────────────────────────────────────────────────────────────────

class StreakBurst {
  /// Affiche l'animation pour [count] (ex: 3 = "3 jours d'affilée").
  /// L'overlay reste affiché jusqu'à ce que l'utilisateur tape n'importe où.
  static Future<void> show(BuildContext context, int count) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late OverlayEntry entry;
    bool removed = false;
    void safeRemove() {
      if (removed) return;
      removed = true;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => _StreakBurstWidget(
        count:     count,
        onDismiss: safeRemove,
      ),
    );
    overlay.insert(entry);
  }
}

class _StreakBurstWidget extends StatefulWidget {
  final int          count;
  final VoidCallback onDismiss;
  const _StreakBurstWidget({required this.count, required this.onDismiss});

  @override
  State<_StreakBurstWidget> createState() => _StreakBurstWidgetState();
}

class _StreakBurstWidgetState extends State<_StreakBurstWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Positioned.fill(
        child: Material(
          color: Colors.black.withValues(alpha: 0.78 * _fade.value),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
            child: Center(
              child: Opacity(
                opacity: _fade.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // GIF flamme + compteur légèrement décalé vers le bas.
                      // Le décalage de ~60 px aligne le chiffre sur le "cœur"
                      // de la flamme plutôt que sur la pointe haute.
                      SizedBox(
                        width:  180,
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/streak.gif',
                              width:  180,
                              height: 180,
                              gaplessPlayback: true,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: Text(
                                '${widget.count}',
                                style: GoogleFonts.firaSansCondensed(
                                  fontSize:   84,
                                  fontWeight: FontWeight.w900,
                                  color:      Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Texte motivant pour fidéliser
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          widget.count == 1
                              ? 'Tu démarres ta streak !\nReviens demain pour la faire grandir.'
                              : '$_streakDayLabel d\'affilée 🔥\nReviens demain pour continuer.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.firaSansCondensed(
                            fontSize:   16,
                            fontWeight: FontWeight.w600,
                            color:      Colors.white.withValues(alpha: 0.95),
                            height:     1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Petit hint dismiss
                      Text(
                        'Tape n\'importe où pour continuer',
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 12,
                          color:    Colors.white.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _streakDayLabel =>
      '${widget.count} jour${widget.count > 1 ? 's' : ''}';
}
