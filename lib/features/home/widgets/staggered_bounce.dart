import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─── DIRECTION ────────────────────────────────────────────────────────────────

enum BounceDirection { fromTop, fromBottom, fromLeft, fromRight }

// ─── WIDGET ───────────────────────────────────────────────────────────────────

/// Wraps [child] avec une animation d'entrée "balle qui rebondit".
/// Utilise [index] pour créer un effet cascade entre les widgets.
///
/// ```dart
/// StaggeredBounceEntry(index: 0, child: MyHeaderWidget())
/// StaggeredBounceEntry(index: 1, child: MyCardWidget())
/// StaggeredBounceEntry(index: 2, child: MyButtonWidget())
/// ```
class StaggeredBounceEntry extends StatefulWidget {
  final Widget child;

  /// Position dans la cascade (0 = premier à arriver)
  final int index;

  /// Délai entre chaque item de la cascade
  final Duration staggerDelay;

  /// Délai initial avant le début de la cascade
  final Duration initialDelay;

  /// Direction depuis laquelle le widget arrive
  final BounceDirection direction;

  const StaggeredBounceEntry({
    super.key,
    required this.child,
    required this.index,
    this.staggerDelay = const Duration(milliseconds: 65),
    this.initialDelay = const Duration(milliseconds: 60),
    this.direction = BounceDirection.fromTop,
  });

  @override
  State<StaggeredBounceEntry> createState() => _StaggeredBounceEntryState();
}

class _StaggeredBounceEntryState extends State<StaggeredBounceEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _position;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _position = CurvedAnimation(
      parent: _ctrl,
      curve: const _BallBounceCurve(),
    );

    _opacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
    );

    final totalDelay = widget.initialDelay +
        Duration(
          milliseconds:
          widget.index * widget.staggerDelay.inMilliseconds,
        );

    Future.delayed(totalDelay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Offset _startOffset() {
    const magnitude = 0.40;
    switch (widget.direction) {
      case BounceDirection.fromTop:
        return const Offset(0, -magnitude);
      case BounceDirection.fromBottom:
        return const Offset(0, magnitude);
      case BounceDirection.fromLeft:
        return const Offset(-magnitude, 0);
      case BounceDirection.fromRight:
        return const Offset(magnitude, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => FractionalTranslation(
        translation:
        Offset.lerp(_startOffset(), Offset.zero, _position.value)!,
        child: Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

// ─── COURBE PERSONNALISÉE ─────────────────────────────────────────────────────

/// Simule une balle (ping-pong / football) qui atterrit :
///   1. Chute rapide (ease-in cubique)
///   2. Rebond 1 — overshoot +9%
///   3. Rebond 2 — micro-overshoot +3%
///   4. Stabilisation
class _BallBounceCurve extends Curve {
  const _BallBounceCurve();

  @override
  double transformInternal(double t) {
    // 1. Chute — ease-in cubique
    if (t < 0.52) {
      final p = t / 0.52;
      return p * p * p;
    }

    // 2. Rebond 1 — overshoot 9%
    if (t < 0.72) {
      final p = (t - 0.52) / 0.20;
      return 1.0 + 0.09 * math.sin(p * math.pi);
    }

    // 3. Rebond 2 — overshoot 3%
    if (t < 0.88) {
      final p = (t - 0.72) / 0.16;
      return 1.0 + 0.03 * math.sin(p * math.pi);
    }

    // 4. Settle final
    final p = (t - 0.88) / 0.12;
    return 1.0 + 0.008 * math.sin(p * math.pi);
  }
}