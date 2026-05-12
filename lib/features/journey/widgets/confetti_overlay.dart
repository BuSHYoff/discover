import 'package:flutter/material.dart';

/// Affiche un GIF de confettis plein écran (non-bloquant) pendant ~2.4s.
/// À appeler dès qu'une récompense (étape validée, jour complété…) est donnée.
class ConfettiOverlay {
  /// Durée par défaut de l'animation à l'écran.
  static const Duration _defaultDuration = Duration(milliseconds: 2400);

  /// Affiche un overlay de confettis au-dessus de tout le contenu courant.
  /// Ne bloque pas les interactions de l'utilisateur (IgnorePointer).
  /// Auto-dismiss après [duration].
  static void show(BuildContext context, {Duration duration = _defaultDuration}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ConfettiLayer(
        duration: duration,
        onCompleted: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _ConfettiLayer extends StatefulWidget {
  final Duration duration;
  final VoidCallback onCompleted;
  const _ConfettiLayer({required this.duration, required this.onCompleted});

  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    // Fade-in rapide, plateau, fade-out doux
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 12),
      TweenSequenceItem(tween: ConstantTween(1.0),         weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 28),
    ]).animate(_ctrl);
    _ctrl.forward().whenComplete(widget.onCompleted);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Positioned doit être enfant direct d'un Stack (Overlay = Stack).
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: FadeTransition(
          opacity: _opacity,
          child: Image.asset(
            'assets/images/confetti.gif',
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
