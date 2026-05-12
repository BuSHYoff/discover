import 'package:flutter/material.dart';
import 'package:discover/core/theme/app_theme.dart';

/// Dessine le chemin courbé en zigzag entre les nœuds de la timeline.
/// `nodeCenters` : positions (x, y) absolues des centres de nœuds dans le widget,
/// du PREMIER (étape 1, en bas) au DERNIER (final, en haut).
/// `progressIndex` : index du dernier nœud complété (-1 = aucun).
class TimelinePathPainter extends CustomPainter {
  final List<Offset> nodeCenters;
  final int progressIndex;
  final Color doneColor;
  final Color lockedColor;

  TimelinePathPainter({
    required this.nodeCenters,
    required this.progressIndex,
    Color? doneColor,
    Color? lockedColor,
  })  : doneColor   = doneColor   ?? const Color(0xFFC8DDD0),
        lockedColor = lockedColor ?? const Color(0xFFE5E5E5);

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeCenters.length < 2) return;

    // ── Trait verrouillé (pointillé sur toute la longueur) ──
    final lockedPaint = Paint()
      ..color = lockedColor
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final lockedPath = _buildPath(nodeCenters);
    _drawDashedPath(canvas, lockedPath, lockedPaint, dashLength: 8, gapLength: 8);

    // ── Trait vert plein jusqu'à progressIndex inclus ──
    if (progressIndex >= 0) {
      final donePaint = Paint()
        ..color = doneColor
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final upTo = (progressIndex + 1).clamp(2, nodeCenters.length);
      final donePath = _buildPath(nodeCenters.sublist(0, upTo));
      canvas.drawPath(donePath, donePaint);
    }
  }

  /// Construit un Path avec des courbes Bézier cubiques entre nœuds consécutifs.
  /// Pour chaque segment de (p1) à (p2), on place les contrôles à mi-hauteur,
  /// alignés en x avec p1 et p2, ce qui crée des "S" doux.
  Path _buildPath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final midY = (p1.dy + p2.dy) / 2;
      path.cubicTo(p1.dx, midY, p2.dx, midY, p2.dx, p2.dy);
    }
    return path;
  }

  void _drawDashedPath(
    Canvas canvas,
    Path source,
    Paint paint, {
    double dashLength = 6,
    double gapLength = 8,
  }) {
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final extract = metric.extractPath(
          distance,
          (distance + dashLength).clamp(0, metric.length),
        );
        canvas.drawPath(extract, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant TimelinePathPainter old) =>
      old.progressIndex != progressIndex ||
      old.nodeCenters.length != nodeCenters.length ||
      !_listEq(old.nodeCenters, nodeCenters);

  static bool _listEq(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Helper pour récupérer les couleurs de la palette app dans le painter.
class TimelinePathColors {
  static Color done(BuildContext context) =>
      Color.lerp(Theme.of(context).colorScheme.primary, Colors.white, 0.55)!;
  static const Color locked = Color(0xFFE5E5E5);
  static const Color cream  = AppColors.cream;
}
