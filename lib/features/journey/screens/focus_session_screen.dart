import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FOCUS SESSION SCREEN — session de consolidation immersive plein écran.
// Si l'user va au bout sans quitter → renvoie true (bonus XP).
// Si l'user quitte ou stoppe → renvoie false.
// ─────────────────────────────────────────────────────────────────────────────

class FocusSessionScreen extends StatefulWidget {
  final String passionName;
  final String stepTitle;
  final int    durationMinutes;

  const FocusSessionScreen({
    super.key,
    required this.passionName,
    required this.stepTitle,
    required this.durationMinutes,
  });

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen>
    with SingleTickerProviderStateMixin {
  late int _remainingSec;
  late int _totalSec;
  Timer? _ticker;
  bool _paused = false;

  late AnimationController _breathCtrl;

  @override
  void initState() {
    super.initState();
    _totalSec     = widget.durationMinutes * 60;
    _remainingSec = _totalSec;

    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _start();

    // Mode immersif (cache la status bar pour la session)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      if (!mounted) return;
      setState(() {
        if (_remainingSec > 0) _remainingSec -= 1;
      });
      if (_remainingSec == 0) {
        _ticker?.cancel();
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) Navigator.of(context).pop(true); // succès
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _breathCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() => _paused = !_paused);
  }

  Future<void> _confirmStop() async {
    setState(() => _paused = true);
    final stop = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A2B25),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                )),
            const SizedBox(height: 22),
            Text('Arrêter la session ?',
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 6),
            Text('Tu perdras le bonus de cette session.',
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 13, color: Colors.white.withValues(alpha: 0.55),
                    height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text('Continuer',
                          style: GoogleFonts.firaSansCondensed(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC44545).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC44545).withValues(alpha: 0.5)),
                      ),
                      alignment: Alignment.center,
                      child: Text('Arrêter',
                          style: GoogleFonts.firaSansCondensed(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF8A8A))),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
    if (stop == true) {
      if (mounted) Navigator.of(context).pop(false);
    } else {
      setState(() => _paused = false);
    }
  }

  String _fmt(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_remainingSec / _totalSec);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmStop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1A14),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A2B25), Color(0xFF0E1A14)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 30),
              child: Column(
                children: [
                  // ── Label + titre ──
                  Text('SESSION DE CONSOLIDATION',
                      style: GoogleFonts.firaSansCondensed(
                        fontSize: 11,
                        letterSpacing: 2.5,
                        color: Colors.white.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 12),
                  Text(widget.stepTitle,
                      style: GoogleFonts.firaSansCondensed(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(
                    'Pratique librement, ancre dans tes mains\ntout ce que tu viens d\'apprendre.',
                    style: GoogleFonts.firaSansCondensed(
                      fontSize: 12, height: 1.5,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  // ── Cercle qui respire + chrono ──
                  AnimatedBuilder(
                    animation: _breathCtrl,
                    builder: (_, __) {
                      final t = _breathCtrl.value;
                      return SizedBox(
                        width: 260, height: 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width:  240 + 20 * t,
                              height: 240 + 20 * t,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF50B482).withValues(alpha: 0.18 + 0.18 * t),
                                  width: 2,
                                ),
                              ),
                            ),
                            Container(
                              width:  220 + 12 * t,
                              height: 220 + 12 * t,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [Color(0x4050B482), Color(0x802D5A3D)],
                                ),
                              ),
                            ),
                            // Anneau de progression
                            SizedBox(
                              width: 220, height: 220,
                              child: CircularProgressIndicator(
                                value: progress.clamp(0.0, 1.0),
                                strokeWidth: 4,
                                backgroundColor: Colors.white.withValues(alpha: 0.08),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF7BC99A)),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_fmt(_remainingSec),
                                    style: GoogleFonts.firaSansCondensed(
                                      fontSize: 56, fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    )),
                                const SizedBox(height: 4),
                                Text(
                                  _paused ? 'EN PAUSE' : 'EN COURS',
                                  style: GoogleFonts.firaSansCondensed(
                                    fontSize: 11,
                                    letterSpacing: 2,
                                    color: _paused
                                        ? const Color(0xFFFFD56B)
                                        : Colors.white.withValues(alpha: 0.55),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  // ── Bonus rappel ──
                  Text('Bonus +30 XP si tu vas au bout',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
                  const SizedBox(height: 18),
                  // ── Actions ──
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _togglePause,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 6),
                                Text(_paused ? 'Reprendre' : 'Pause',
                                    style: GoogleFonts.firaSansCondensed(
                                        fontSize: 13, fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _confirmStop,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC44545).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                  color: const Color(0xFFC44545).withValues(alpha: 0.3)),
                            ),
                            alignment: Alignment.center,
                            child: Text('Arrêter',
                                style: GoogleFonts.firaSansCondensed(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFF8A8A))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
