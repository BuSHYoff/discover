import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/app_user.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/core/services/streak_service.dart';
import 'package:discover/core/theme/app_theme.dart';
import 'package:discover/features/journey/widgets/journey_progress.dart';
import 'package:discover/features/journey/widgets/timeline_path_painter.dart';
import 'package:discover/features/journey/widgets/timeline_node.dart';
import 'package:discover/features/journey/widgets/timeline_video_card.dart';
import 'package:discover/features/journey/widgets/step_sheets.dart';
import 'package:discover/features/journey/widgets/confetti_overlay.dart';
import 'package:discover/features/journey/widgets/streak_burst.dart';
import 'package:discover/features/journey/screens/completion_screen.dart';
import 'package:discover/features/journey/screens/daily_stepper_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// JOURNEY SCREEN — Timeline zigzag style Duolingo, inversée bas → haut.
// Étape 1 (matériel) en bas, étape finale (partager) en haut.
// ─────────────────────────────────────────────────────────────────────────────

class JourneyScreen extends StatefulWidget {
  final Passion passion;
  final JourneyProgress progress;
  const JourneyScreen({
    super.key,
    required this.passion,
    required this.progress,
  });

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  AIContent? _aiContent;
  bool       _aiLoading = true;

  Timer? _ticker; // pour refresh des compteurs "dans Xh"

  /// Streak actuel — chargé depuis StreakService au mount.
  /// Le service garde un cache de session, donc revenir sur l'écran n'entraîne
  /// pas de nouvel appel réseau.
  UserStreak? _streak;

  // ── Layout constants ──────────────────────────────────────────────────────
  static const double _stepRowHeight  = 132;
  static const double _videoRowHeight = 160;
  static const double _topPadding     = 24;
  static const double _bottomPadding  = 110;

  // Pattern de zigzag — décalages horizontaux (px) selon l'index logique
  static const List<double> _xOffsetPattern = [-80, 80, -90, 70, -60, 90, -50, 80];

  JourneyProgress get _prog => widget.progress;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadAIContent();
    _loadStreak();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadStreak() async {
    final s = await StreakService.fetch();
    if (mounted) setState(() => _streak = s);
  }

  /// Tick le streak après une complétion de jour journalier.
  /// Si le count a augmenté → affiche l'overlay festif.
  /// Backend dédup par date donc safe d'appeler même si déjà tické aujourd'hui.
  Future<void> _tickStreakAfterDailyCompletion() async {
    final before = _streak?.count ?? 0;
    final after  = await StreakService.tick();
    if (!mounted) return;
    setState(() => _streak = after);
    if (after.count > before) {
      // Petit délai pour laisser le confetti respirer avant le burst
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      await StreakBurst.show(context, after.count);
    }
  }

  /// Bottom sheet d'information sur la streak, affiché au tap sur la flamme
  /// du header. Explique la règle de maintien : pratiquer chaque jour.
  void _showStreakInfoSheet(int count) {
    HapticFeedback.selectionClick();
    final primary = Theme.of(context).colorScheme.primary;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 18),
                // GIF + count
                SizedBox(
                  width: 92, height: 92,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset('assets/images/streak.gif',
                          width: 92, height: 92, gaplessPlayback: true),
                      Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: Text('$count',
                            style: GoogleFonts.firaSansCondensed(
                              fontSize: 38, fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  count > 1
                      ? '$count jours d\'affilée'
                      : 'Tu démarres ta streak',
                  style: GoogleFonts.firaSansCondensed(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: AppColors.ink),
                ),
                const SizedBox(height: 14),
                Text(
                  'Pratique au moins un jour de parcours par jour pour faire grandir ta streak. '
                  'Si tu passes une journée sans rien compléter, elle repart à zéro.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.firaSansCondensed(
                      fontSize: 14, color: AppColors.inkSoft, height: 1.5),
                ),
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text('J\'ai compris',
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom sheet d'information quand l'utilisateur tape sur un nœud verrouillé.
  /// Le texte est dynamique selon ce qui bloque :
  ///   - Jour 1     → "Tu dois d'abord valider le matériel"
  ///   - Jour N>1   → "Tu dois compléter le jour N-1 (attente 24h après)"
  ///   - Final      → "Tu dois compléter tous les jours du parcours"
  void _showLockedInfoSheet(int logicalIdx) {
    final isFinal = logicalIdx == _totalSteps - 1;
    final primary = Theme.of(context).colorScheme.primary;

    // Détermine ce qui bloque + le message à afficher
    final String title;
    final String body;

    if (logicalIdx == 1) {
      // Jour 1 : doit valider le matériel
      title = 'Matériel à valider';
      body  = 'Pour commencer le jour 1, tu dois d\'abord valider l\'étape '
              'matériel — coche tous les éléments puis appuie sur '
              '"Valider l\'étape".';
    } else if (isFinal) {
      title = 'Parcours à terminer';
      body  = 'Tu dois compléter tous les jours du parcours avant de '
              'pouvoir débloquer cette étape finale.';
    } else {
      // Jour N>1 : doit compléter jour N-1, ET potentiellement attendre 24h
      final dayIdx        = logicalIdx - 1;
      final prevDayNumber = dayIdx;          // jour N-1 affiché
      final remainingMs   = _prog.dailyRemainingMs(dayIdx);
      final hours         = remainingMs > 0 ? (remainingMs / 3600000).ceil() : 0;

      if (hours > 0) {
        title = 'Reviens dans ${hours}h';
        body  = 'Le jour ${dayIdx + 1} se débloquera ${hours}h après avoir '
                'terminé le jour $prevDayNumber. Profite de la pause pour '
                'pratiquer ce que tu as appris !';
      } else {
        title = 'Jour précédent à terminer';
        body  = 'Tu dois d\'abord compléter le jour $prevDayNumber avant '
                'de pouvoir accéder au jour ${dayIdx + 1}.';
      }
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 18),
                // Cadenas dans un cercle primary clair
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_rounded, color: primary, size: 30),
                ),
                const SizedBox(height: 14),
                Text(title,
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 20, fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 12),
                Text(body,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 14, color: AppColors.inkSoft, height: 1.5)),
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text('J\'ai compris',
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom sheet pour les vidéos / tips verrouillés.
  /// Même style visuel que la sheet des nœuds verrouillés ; texte adapté
  /// au type d'élément.
  void _showLockedItemSheet({required _LockedItemKind kind}) {
    final primary = Theme.of(context).colorScheme.primary;

    final String title;
    final String body;
    if (kind == _LockedItemKind.video) {
      title = 'Vidéo verrouillée';
      body  = 'Cette vidéo se débloquera quand tu auras atteint l\'étape '
              'correspondante. Continue ton parcours pour y accéder !';
    } else {
      title = 'Astuce verrouillée';
      body  = 'Cette astuce se débloquera quand tu auras atteint l\'étape '
              'correspondante. Continue ton parcours pour la découvrir !';
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_rounded, color: primary, size: 30),
                ),
                const SizedBox(height: 14),
                Text(title,
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 20, fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 12),
                Text(body,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 14, color: AppColors.inkSoft, height: 1.5)),
                const SizedBox(height: 22),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text('J\'ai compris',
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadAIContent() async {
    final content = await AIContentProvider.getFor(widget.passion.id);
    if (!mounted) return;
    setState(() {
      _aiContent = content;
      _aiLoading = false;
      if (content.id.isNotEmpty) {
        _prog.initTotals(
          thisWeek:  content.steps.length,
          materials: content.materials.length,
        );
      }
    });
  }

  /// Top vidéos pré-seedées en BDD (max 3, utilisées dans la timeline).
  List<AIVideo> get _topVideos => _aiContent?.topVideos.take(3).toList() ?? const [];

  // ── Computed: total steps (matériel + N journées + final) ─────────────────

  int get _totalSteps {
    final daily = _aiContent?.steps.length ?? 0;
    return 1 + daily + 1;
  }

  /// Index logique du dernier nœud complété (-1 si rien).
  int get _progressIndex {
    final c = _aiContent;
    if (c == null) return -1;
    int idx = -1;
    final allMatChecked = _prog.materialsChecked.isNotEmpty &&
        _prog.materialsChecked.every((v) => v);
    if (allMatChecked) idx = 0;
    for (int i = 0; i < c.steps.length; i++) {
      if (i < _prog.thisWeekChecked.length && _prog.thisWeekChecked[i]) {
        idx = 1 + i;
      } else {
        break;
      }
    }
    if (_prog.completed) idx = _totalSteps - 1;
    return idx;
  }

  // ── Construction de la liste d'items (du logique 0 → N-1) ─────────────────

  /// Renvoie pour chaque index logique l'état de nœud.
  /// Règle d'accès :
  ///   - Matériel (0) : toujours accessible
  ///   - Jour 1 (1)   : verrouillé jusqu'à validation du matériel (cadenas)
  ///   - Jour 2+ (≥2) : verrouillé jusqu'au timer 24h après le jour précédent
  ///   - Final        : verrouillé jusqu'à ce que tous les jours soient faits
  TimelineNodeState _stateFor(int logicalIdx) {
    final isFinal = logicalIdx == _totalSteps - 1;

    // Étape finale
    if (isFinal) {
      if (_prog.completed) return TimelineNodeState.finalUnlocked;
      // Débloquer quand tous les jours sont cochés
      final c = _aiContent;
      if (c != null && _prog.thisWeekChecked.length >= c.steps.length &&
          _prog.thisWeekChecked.every((v) => v)) {
        return TimelineNodeState.finalUnlocked;
      }
      return TimelineNodeState.finalLocked;
    }

    // Matériel (logical 0)
    final matAllChecked = _prog.materialsChecked.isNotEmpty &&
        _prog.materialsChecked.every((v) => v);
    if (logicalIdx == 0) {
      return matAllChecked ? TimelineNodeState.completed : TimelineNodeState.current;
    }

    // Jours (logical 1..N-2)
    final dayIdx = logicalIdx - 1;
    final isDone = dayIdx < _prog.thisWeekChecked.length &&
        _prog.thisWeekChecked[dayIdx];
    if (isDone) return TimelineNodeState.completed;

    // Jour 1 : verrouillé tant que le matériel n'a pas été validé entièrement
    if (dayIdx == 0) {
      return matAllChecked ? TimelineNodeState.current : TimelineNodeState.locked;
    }

    // Jour 2+ : accessible si timer écoulé
    if (_prog.isDailyUnlocked(dayIdx)) return TimelineNodeState.current;
    return TimelineNodeState.locked;
  }

  // ── Position des vidéos (slots 0/1/2) et tips sur la liste logique ──────────

  /// Renvoie l'index logique APRÈS lequel on insère la vidéo `slot`.
  List<int> get _videoSlotPositions {
    final n = _totalSteps;
    if (n < 3) return const [];
    return [
      0,                 // après matériel
      (n / 2).floor(),   // au milieu
      n - 2,             // juste avant final
    ];
  }

  /// Tips à afficher (max 3, extraits de _aiContent.tips).
  List<String> get _tips {
    final t = _aiContent?.tips ?? [];
    return t.take(3).toList();
  }

  /// Positions des tips (index logique APRÈS lequel on insère le tip `slot`).
  /// On les intercale entre les jours, du côté opposé aux vidéos.
  List<int> get _tipSlotPositions {
    final n = _totalSteps;
    if (n < 2) return const [];
    // Positions décalées d'un pas par rapport aux vidéos
    return [
      (n / 4).floor().clamp(1, n - 2),       // ~1/4
      (n / 2 + 1).floor().clamp(1, n - 2),   // ~milieu+1
      (n - 3).clamp(1, n - 2),                // ~fin
    ];
  }

  // ── Calcul des positions (y) pour le painter ──────────────────────────────

  /// Liste des items rendus top→bottom (dans l'ordre visuel : final tout en haut).
  ({List<_RenderItem> items, List<Offset> nodeCenters, double totalHeight})
      _buildLayout(double width) {
    final items = <_RenderItem>[];
    // ── 1. Construit la liste logique 0..N-1 avec vidéos + tips intercalés
    final logical = <_RenderItem>[];
    final videoSlots = _videoSlotPositions;
    final tipSlots   = _tipSlotPositions;
    final tips       = _tips;
    for (int i = 0; i < _totalSteps; i++) {
      logical.add(_RenderItem.step(i));
      // Vidéo après cet index ?
      final vSlot = videoSlots.indexOf(i);
      if (vSlot >= 0 && vSlot < _topVideos.length) {
        logical.add(_RenderItem.video(vSlot));
      }
      // Tip après cet index ?
      final tSlot = tipSlots.indexOf(i);
      if (tSlot >= 0 && tSlot < tips.length) {
        logical.add(_RenderItem.tip(tSlot));
      }
    }
    // ── 2. Inverse pour le rendu (final au top, matériel au bas)
    items.addAll(logical.reversed);

    // ── 3. Calcule y pour chaque item du haut vers le bas
    double y = _topPadding;
    final stepCenters = <int, double>{};
    for (final item in items) {
      final h = item.kind == _ItemKind.step ? _stepRowHeight : _videoRowHeight;
      item.yTop = y;
      item.yCenter = y + h / 2;
      if (item.kind == _ItemKind.step) {
        stepCenters[item.index] = item.yCenter;
      }
      y += h;
    }
    final totalHeight = y + _bottomPadding;

    // ── 4. Centres en ordre logique 0..N-1
    // Matériel (0) et Final (N-1) sont visuellement centrés (nodeOff = 0),
    // donc le painter doit pointer vers x = centerX, pas vers le pattern.
    final centerX = width / 2;
    final centers = List.generate(_totalSteps, (i) {
      final yc = stepCenters[i] ?? 0;
      final isFinal    = i == _totalSteps - 1;
      final isMaterial = i == 0;
      final off = (isMaterial || isFinal)
          ? 0.0
          : _xOffsetPattern[i % _xOffsetPattern.length];
      return Offset(centerX + off, yc);
    });

    return (items: items, nodeCenters: centers, totalHeight: totalHeight);
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _onTapNode(int logicalIdx) async {
    final c = _aiContent;
    if (c == null) return;
    HapticFeedback.lightImpact();

    final state = _stateFor(logicalIdx);

    // Étape verrouillée → vibration + bottom sheet explicative.
    if (state == TimelineNodeState.locked || state == TimelineNodeState.finalLocked) {
      HapticFeedback.heavyImpact();
      _showLockedInfoSheet(logicalIdx);
      return;
    }

    // ── Étape Matériel (logical 0) ──
    if (logicalIdx == 0) {
      await MaterialsSheet.show(context,
        materials:       c.materials,
        passionName:     widget.passion.name,
        initialChecked:  _prog.materialsChecked,
        onToggleItem:    (i, v) async {
          if (i < _prog.materialsChecked.length) {
            _prog.materialsChecked[i] = v;
            _prog.updateCounts(
              thisWeek:  _prog.thisWeekChecked,
              materials: _prog.materialsChecked,
            );
            // Pas de confettis par item — uniquement à la validation finale
            // ("Valider l'étape") pour ne pas saturer l'utilisateur.
            if (mounted) setState(() {});
          }
        },
        onValidate:      () async {
          _prog.updateStep(0);
          // Le 1er jour était déjà débloqué via initTotals
          if (_prog.thisWeekTotal > 0) {
            _prog.unlockDailyStepNow(0);
          }
          if (!mounted) return 0;
          setState(() {});
          ConfettiOverlay.show(context, duration: const Duration(seconds: 3));
          return 0;
        },
      );
      return;
    }

    // ── Étape finale (Partager) ──
    if (logicalIdx == _totalSteps - 1) {
      // Marque comme finalisée AVANT la navigation, pour que la timeline
      // soit déjà à jour quand l'utilisateur revient en arrière.
      // Le confetti s'affichera dans la CompletionScreen elle-même.
      if (!_prog.completed) _prog.markCompleted();
      if (mounted) setState(() {});

      await Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true, // animation slide-up depuis le bas
        builder: (_) => CompletionScreen(passion: widget.passion),
      ));
      if (mounted) setState(() {});
      return;
    }

    // ── Étape journalière (1..N-2) → ouvre le stepper plein écran ──
    final dailyIdx = logicalIdx - 1;
    if (dailyIdx < 0 || dailyIdx >= c.steps.length) return;

    // Initialise la matrice subtasksChecked si pas encore fait
    final subtaskCounts = c.steps.map((s) => s.subtasks.length).toList();
    _prog.initSubtasks(subtaskCounts);

    // Capture pour détecter si un jour est passé de "non coché" à "coché"
    // au retour du DailyStepperScreen → si oui, on tick le streak.
    final wasDayChecked = dailyIdx < _prog.thisWeekChecked.length
        && _prog.thisWeekChecked[dailyIdx];

    await Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => DailyStepperScreen(
        passion:  widget.passion,
        progress: _prog,
        dayIdx:   dailyIdx,
        step:     c.steps[dailyIdx],
      ),
    ));

    if (!mounted) return;
    setState(() {});

    final isDayCheckedNow = dailyIdx < _prog.thisWeekChecked.length
        && _prog.thisWeekChecked[dailyIdx];
    if (!wasDayChecked && isDayCheckedNow) {
      // Le user a complété ce jour pendant la session → tick + burst si nouveau jour.
      // Fire-and-forget : on ne bloque pas le retour visuel.
      unawaited(_tickStreakAfterDailyCompletion());
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPadding    = MediaQuery.of(context).padding.top;
    final primary = Theme.of(context).colorScheme.primary;

    if (_aiLoading) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircularProgressIndicator(color: primary, strokeWidth: 2),
            const SizedBox(height: 16),
            Text('Chargement de ton parcours…',
                style: GoogleFonts.firaSansCondensed(fontSize: 14, color: AppColors.inkSoft)),
          ]),
        ),
      );
    }

    if (_aiContent == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(child: Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.inkSoft.withValues(alpha: 0.4), size: 48),
            const SizedBox(height: 16),
            Text('Contenu indisponible',
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 8),
            Text('Impossible de charger le programme pour cette passion.',
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 14, color: AppColors.inkSoft, height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(14)),
                child: Text('Retour',
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ]),
        ))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(children: [
        // ── HEADER ────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(
                onTap: () {
                  widget.progress.syncToFirestore();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.close_rounded, size: 16, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Parcours ${widget.passion.name}',
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              // Streak — GIF flamme + nombre. Caché quand 0 ou pas encore chargé.
              // Tap → popup d'info explicative.
              if ((_streak?.count ?? 0) > 0) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showStreakInfoSheet(_streak!.count),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/streak.gif',
                          width: 22, height: 22, gaplessPlayback: true),
                      const SizedBox(width: 2),
                      Text('${_streak!.count}',
                          style: GoogleFonts.firaSansCondensed(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: const Color(0xFFFF5722))),
                    ],
                  ),
                ),
              ],
            ]),
          ]),
        ),

        // ── TIMELINE ────────────────────────────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final layout = _buildLayout(constraints.maxWidth);
              return SingleChildScrollView(
                reverse: true,  // démarre en bas (étape 1 visible)
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: layout.totalHeight,
                  child: Stack(
                    children: [
                      // ── Chemin courbé ──
                      Positioned.fill(
                        child: CustomPaint(
                          painter: TimelinePathPainter(
                            nodeCenters: layout.nodeCenters,
                            progressIndex: _progressIndex,
                            doneColor: TimelinePathColors.done(ctx),
                          ),
                        ),
                      ),
                      // ── Items (nœuds + vidéos) ──
                      for (final item in layout.items)
                        _positionItem(item, constraints.maxWidth),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _positionItem(_RenderItem item, double width) {
    final centerX = width / 2;
    if (item.kind == _ItemKind.step) {
      final state = _stateFor(item.index);
      final off      = _xOffsetPattern[item.index % _xOffsetPattern.length];
      final isFinal    = item.index == _totalSteps - 1;
      final isMaterial = item.index == 0;
      final IconData icon = isFinal
          ? Icons.emoji_events_rounded
          : (isMaterial ? Icons.shopping_bag_rounded : Icons.flag_rounded);
      // Mat (idx=0) et Final (idx=totalSteps-1) toujours centrés
      final double nodeOff = (isMaterial || isFinal) ? 0 : off;
      final String? timerText = _timerTextFor(item.index, state);

      // Tous les états sont cliquables — même verrouillés : un tap sur un
      // cadenas ou sur le trophée verrouillé ouvre un bottom sheet d'info
      // qui explique ce qui débloque l'étape (cf. _showLockedInfoSheet).
      const bool tappable = true;

      return Positioned(
        top: item.yTop,
        height: _stepRowHeight,
        left: 0, right: 0,
        child: Center(
          child: Transform.translate(
            offset: Offset(nodeOff, 0),
            child: TimelineNode(
              icon:      icon,
              state:     state,
              timerText: timerText,
              onTap:     tappable ? () => _onTapNode(item.index) : null,
            ),
          ),
        ),
      );
    } else if (item.kind == _ItemKind.video) {
      // Vidéo — alterner gauche/droite selon le slot
      final isLeft   = item.index % 2 == 0;
      final video    = _topVideos[item.index];
      final stepPos  = _videoSlotPositions[item.index];
      final locked   = _isPositionLocked(stepPos);
      return Positioned(
        top: item.yTop,
        height: _videoRowHeight,
        left:  isLeft ? 18 : centerX + 30,
        right: isLeft ? centerX + 30 : 18,
        child: Align(
          alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          child: TimelineVideoCard(
            video:       video,
            locked:      locked,
            onLockedTap: () => _showLockedItemSheet(kind: _LockedItemKind.video),
          ),
        ),
      );
    } else {
      // Tip — bouton icone seul, côté opposé aux vidéos
      final isLeft   = item.index % 2 != 0;
      final tipText  = _tips[item.index];
      final stepPos  = _tipSlotPositions[item.index];
      final locked   = _isPositionLocked(stepPos);
      return Positioned(
        top: item.yTop,
        height: _videoRowHeight,
        left:  isLeft ? 30 : centerX + 30,
        right: isLeft ? centerX + 30 : 30,
        child: Align(
          alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          child: _TipButton(
            tip:         tipText,
            locked:      locked,
            onLockedTap: () => _showLockedItemSheet(kind: _LockedItemKind.tip),
          ),
        ),
      );
    }
  }

  /// Une vidéo / tip est verrouillé tant que l'étape juste avant n'a pas été
  /// atteinte (i.e. cette étape est encore `locked` ou `finalLocked`).
  bool _isPositionLocked(int stepIdx) {
    final s = _stateFor(stepIdx);
    return s == TimelineNodeState.locked || s == TimelineNodeState.finalLocked;
  }

  String? _timerTextFor(int idx, TimelineNodeState state) {
    if (state != TimelineNodeState.locked) return null;
    if (idx > 0 && idx <= _prog.thisWeekTotal) {
      final dailyIdx = idx - 1;
      final ms = _prog.dailyRemainingMs(dailyIdx);
      if (ms > 0) {
        final totalSec = (ms / 1000).ceil();
        final h = totalSec ~/ 3600;
        final m = (totalSec % 3600) ~/ 60;
        final s = totalSec % 60;
        return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      }
    }
    return null;
  }
}

// ── Internal data ──────────────────────────────────────────────────────────────

enum _ItemKind { step, video, tip }
enum _LockedItemKind { video, tip }

class _RenderItem {
  final _ItemKind kind;
  final int       index; // index logique pour step, slot pour video/tip
  double yTop = 0;
  double yCenter = 0;

  _RenderItem.step(this.index)  : kind = _ItemKind.step;
  _RenderItem.video(this.index) : kind = _ItemKind.video;
  _RenderItem.tip(this.index)   : kind = _ItemKind.tip;
}

// ── Tip button widget — icone seule, popup au tap ───────────────────────────────

class _TipButton extends StatelessWidget {
  final String         tip;
  final bool           locked;
  final VoidCallback?  onLockedTap;
  const _TipButton({
    required this.tip,
    this.locked = false,
    this.onLockedTap,
  });

  void _showTip(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lightbulb_rounded, color: primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('Astuce',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: primary)),
                ],
              ),
              const SizedBox(height: 14),
              Text(tip,
                  style: GoogleFonts.firaSansCondensed(
                      fontSize: 14, color: AppColors.ink, height: 1.5)),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text('OK',
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: primary)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked
          ? () {
              HapticFeedback.heavyImpact();
              onLockedTap?.call();
            }
          : () => _showTip(context),
      child: Opacity(
        opacity: locked ? 0.30 : 1.0,
        child: SizedBox(
          width: 100, height: 100,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset('assets/images/tips.gif',
                gaplessPlayback: true, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

