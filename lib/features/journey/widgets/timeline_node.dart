import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

enum TimelineNodeState { completed, current, locked, finalLocked, finalUnlocked }

class TimelineNode extends StatefulWidget {
  final IconData icon;
  final TimelineNodeState state;
  /// Texte de countdown affiché sous le cercle quand l'étape est verrouillée.
  /// Ex: "23h" ou "2j". Null → rien affiché.
  final String? timerText;
  final VoidCallback? onTap;

  const TimelineNode({
    super.key,
    required this.icon,
    required this.state,
    this.timerText,
    this.onTap,
  });

  @override
  State<TimelineNode> createState() => _TimelineNodeState();
}

class _TimelineNodeState extends State<TimelineNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringCtrl;
  late final Animation<double>   _ringAnim;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  // ── Couleurs / styles ─────────────────────────────────────────────────────

  Color _bg(Color primary) {
    switch (widget.state) {
      case TimelineNodeState.completed:     return Color.lerp(primary, Colors.white, 0.65)!;
      case TimelineNodeState.current:       return primary;
      case TimelineNodeState.locked:        return const Color(0xFFF0F0F0);
      case TimelineNodeState.finalLocked:   return const Color(0xFFF7E7AB).withValues(alpha: 0.5);
      case TimelineNodeState.finalUnlocked: return const Color(0xFFD4A93A);
    }
  }

  Color _iconColor(Color primary) {
    switch (widget.state) {
      case TimelineNodeState.completed:     return primary;
      case TimelineNodeState.current:       return Colors.white;
      case TimelineNodeState.locked:        return AppColors.inkSoft;
      case TimelineNodeState.finalLocked:   return const Color(0xFFD4A93A).withValues(alpha: 0.7);
      case TimelineNodeState.finalUnlocked: return Colors.white;
    }
  }

  IconData _displayedIcon() {
    if (widget.state == TimelineNodeState.locked)        return Icons.lock_rounded;
    if (widget.state == TimelineNodeState.finalLocked)   return Icons.emoji_events_outlined;
    if (widget.state == TimelineNodeState.finalUnlocked) return Icons.emoji_events_rounded;
    return widget.icon;
  }

  double _opacity() => widget.state == TimelineNodeState.completed ? 0.85 : 1.0;

  bool get _isCurrent     => widget.state == TimelineNodeState.current;
  bool get _isLocked      => widget.state == TimelineNodeState.locked
                          || widget.state == TimelineNodeState.finalLocked;
  /// Tous les états cliquables — y compris `locked` et `finalLocked` pour
  /// qu'un tap déclenche le bottom sheet d'information sur ce qui débloque
  /// l'étape (cf. `_showLockedInfoSheet` côté JourneyScreen).
  bool get _isInteractive => widget.state == TimelineNodeState.current
                          || widget.state == TimelineNodeState.completed
                          || widget.state == TimelineNodeState.finalUnlocked
                          || widget.state == TimelineNodeState.locked
                          || widget.state == TimelineNodeState.finalLocked;

  /// Affiche le GIF reward.gif (trophée animé) uniquement sur le bouton final débloqué.
  /// Matériel et Jours conservent leurs icônes Material classiques.
  bool get _showRewardGif => widget.state == TimelineNodeState.finalUnlocked;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final circle = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 76, height: 76,
      decoration: BoxDecoration(
        color: _bg(primary),
        shape: BoxShape.circle,
        boxShadow: _isCurrent
            ? [BoxShadow(
                color: primary.withValues(alpha: 0.45),
                blurRadius: 24, offset: const Offset(0, 8))]
            : [BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: _showRewardGif
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/images/reward.gif',
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            )
          : Icon(_displayedIcon(), color: _iconColor(primary), size: 32),
    );

    final node = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (_isCurrent)
          AnimatedBuilder(
            animation: _ringAnim,
            builder: (_, __) {
              final t = _ringAnim.value;
              return Container(
                width: 76 + 24 * t,
                height: 76 + 24 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primary.withValues(alpha: 0.45 * (1 - t)),
                    width: 3,
                  ),
                ),
              );
            },
          ),
        Opacity(opacity: _opacity(), child: circle),
      ],
    );

    // Timer sous le cadenas (uniquement quand verrouillé + texte fourni)
    final showTimer = _isLocked && widget.timerText != null && widget.timerText!.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _isInteractive ? widget.onTap : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          node,
          if (showTimer) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Text(
                widget.timerText!,
                style: GoogleFonts.firaSansCondensed(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
