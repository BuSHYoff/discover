import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/core/theme/app_theme.dart';
import 'package:discover/features/journey/widgets/journey_progress.dart';
import 'package:discover/features/journey/widgets/subtask_page.dart';
import 'package:discover/features/journey/widgets/confetti_overlay.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DAILY STEPPER SCREEN — flow plein écran d'un Jour de parcours.
// Stepper de sous-tâches → écran de complétion → optionnel session focus.
// ─────────────────────────────────────────────────────────────────────────────

class DailyStepperScreen extends StatefulWidget {
  final Passion         passion;
  final JourneyProgress progress;
  final int             dayIdx;       // 0-based
  final PassionStep     step;

  const DailyStepperScreen({
    super.key,
    required this.passion,
    required this.progress,
    required this.dayIdx,
    required this.step,
  });

  @override
  State<DailyStepperScreen> createState() => _DailyStepperScreenState();
}

class _DailyStepperScreenState extends State<DailyStepperScreen> {
  late final PageController _pageCtrl;
  late int _currentIdx;
  bool _showCompletion = false;

  List<PassionSubtask> get _subtasks => widget.step.subtasks;

  @override
  void initState() {
    super.initState();
    // Reprend là où l'user s'est arrêté : 1ère sous-tâche non cochée
    _currentIdx = _findFirstUnchecked();
    _pageCtrl = PageController(initialPage: _currentIdx);

    // Si tout est déjà coché à l'arrivée : montre l'écran de complétion
    if (widget.progress.isDayFullyChecked(widget.dayIdx)) {
      _showCompletion = true;
    }
  }

  int _findFirstUnchecked() {
    for (int i = 0; i < _subtasks.length; i++) {
      if (!widget.progress.isSubtaskChecked(widget.dayIdx, i)) return i;
    }
    return 0;
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _onSucceeded() async {
    final wasChecked = widget.progress.isSubtaskChecked(widget.dayIdx, _currentIdx);
    if (!wasChecked) {
      widget.progress.checkSubtask(widget.dayIdx, _currentIdx);
      if (mounted) ConfettiOverlay.show(context);
    }
    HapticFeedback.lightImpact();
    _goNext();
  }

  void _onSkipped() {
    HapticFeedback.selectionClick();
    _goNext();
  }

  void _goNext() {
    if (_currentIdx + 1 >= _subtasks.length) {
      // Dernière sous-tâche : aller directement à l'écran de complétion
      _finishDay();
      return;
    }
    setState(() => _currentIdx += 1);
    _pageCtrl.animateToPage(
      _currentIdx,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _finishDay() {
    if (widget.progress.isDayFullyChecked(widget.dayIdx)) {
      widget.progress.completeDailyStep(widget.dayIdx);
      widget.progress.updateStep(widget.dayIdx + 1);
    }
    HapticFeedback.mediumImpact();
    setState(() => _showCompletion = true);
    // Confetti à l'arrivée sur l'écran de complétion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ConfettiOverlay.show(context, duration: const Duration(seconds: 3));
    });
  }

  void _restartDay() {
    widget.progress.resetDay(widget.dayIdx);
    setState(() {
      _showCompletion  = false;
      _currentIdx      = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageCtrl.hasClients) _pageCtrl.jumpToPage(0);
    });
  }

  void _goPrev() {
    if (_currentIdx == 0) return;
    setState(() => _currentIdx -= 1);
    _pageCtrl.animateToPage(
      _currentIdx,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_showCompletion) return _buildCompletionScreen();
    return _buildStepper();
  }

  // ── Stepper view ────────────────────────────────────────────────────────────

  Widget _buildStepper() {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header (back / dots / close) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  // Flèche retour : invisible sur la 1ère étape
                  if (_currentIdx > 0)
                    _IconBtn(
                      icon: Icons.arrow_back_rounded,
                      enabled: true,
                      onTap: _goPrev,
                    )
                  else
                    const SizedBox(width: 38),
                  const SizedBox(width: 10),
                  Expanded(child: _ProgressDots(
                    total: _subtasks.length,
                    current: _currentIdx,
                    progress: widget.progress,
                    dayIdx: widget.dayIdx,
                    color: primary,
                  )),
                  const SizedBox(width: 10),
                  _IconBtn(
                    icon: Icons.close_rounded,
                    enabled: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // ── PageView des sous-tâches ──
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subtasks.length,
                itemBuilder: (_, i) {
                  final s = _subtasks[i];
                  return SubtaskPage(
                    subtask:     s,
                    indexInDay:  i,
                    totalInDay:  _subtasks.length,
                    dayNumber:   widget.dayIdx + 1,
                    alreadyDone: widget.progress.isSubtaskChecked(widget.dayIdx, i),
                    onSucceeded: _onSucceeded,
                    onSkipped:   _onSkipped,
                  );
                },
              ),
            ),
            // ── Footer CTA ──
            _buildSubtaskFooter(primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtaskFooter(Color primary) {
    final alreadyDone = _currentIdx < _subtasks.length &&
        widget.progress.isSubtaskChecked(widget.dayIdx, _currentIdx);
    final isLast = _currentIdx == _subtasks.length - 1;
    final ctaLabel = isLast
        ? 'Terminer le jour'
        : (alreadyDone ? 'Déjà fait · suivant' : 'J\'ai réussi');
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _onSucceeded,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: primary.withValues(alpha: 0.3),
                    blurRadius: 16, offset: const Offset(0, 6))],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isLast || alreadyDone
                        ? Icons.check_circle_rounded
                        : Icons.check_rounded,
                    color: Colors.white, size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ctaLabel,
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Completion view ────────────────────────────────────────────────────────

  Widget _buildCompletionScreen() {
    final primary = Theme.of(context).colorScheme.primary;
    final allChecked = widget.progress.isDayFullyChecked(widget.dayIdx);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  const SizedBox(width: 38),
                  Expanded(child: _ProgressDots(
                    total:    _subtasks.length,
                    current:  _subtasks.length - 1,
                    progress: widget.progress,
                    dayIdx:   widget.dayIdx,
                    color:    primary,
                    allDone:  true,
                  )),
                  _IconBtn(
                    icon: Icons.close_rounded,
                    enabled: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
                child: Column(
                  children: [
                    // Trophée animé (reward.gif)
                    SizedBox(
                      width: 160, height: 160,
                      child: Image.asset(
                        'assets/images/reward.gif',
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text('Jour ${widget.dayIdx + 1} terminé !',
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 24, fontWeight: FontWeight.w700,
                            color: primary)),
                    const SizedBox(height: 8),
                    Text(
                      allChecked
                          ? 'Tu as bouclé toutes tes étapes du jour. Prochain Jour disponible dans 24h.'
                          : 'Tu peux revenir compléter les étapes manquantes plus tard.',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 13.5, color: AppColors.inkSoft, height: 1.55),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Récap des sous-tâches
                    ..._subtasks.asMap().entries.map((e) {
                      final done = widget.progress.isSubtaskChecked(widget.dayIdx, e.key);
                      return _CompletionRecapItem(
                        title:   e.value.title,
                        done:    done,
                        primary: primary,
                      );
                    }),
                  ],
                ),
              ),
            ),
            // CTAs de complétion — collés au bas du téléphone
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(
                            color: primary.withValues(alpha: 0.3),
                            blurRadius: 12, offset: const Offset(0, 5))],
                      ),
                      alignment: Alignment.center,
                      child: Text('Retour au parcours guidé',
                          style: GoogleFonts.firaSansCondensed(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                  GestureDetector(
                    onTap: _restartDay,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded,
                              size: 14, color: AppColors.inkSoft),
                          const SizedBox(width: 5),
                          Text('Recommencer le jour',
                              style: GoogleFonts.firaSansCondensed(
                                  fontSize: 13, fontWeight: FontWeight.w500,
                                  color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ── Sub-widgets internes ─────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData     icon;
  final bool         enabled;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
          ),
          child: Icon(icon, size: 17, color: AppColors.ink),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int total;
  final int current;
  final JourneyProgress progress;
  final int dayIdx;
  final Color color;
  final bool allDone;
  const _ProgressDots({
    required this.total,
    required this.current,
    required this.progress,
    required this.dayIdx,
    required this.color,
    this.allDone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isDone   = allDone || progress.isSubtaskChecked(dayIdx, i);
        final isActive = !allDone && i == current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 6,
            decoration: BoxDecoration(
              color: isDone || isActive ? color : Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(100),
              boxShadow: isActive
                  ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6)]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class _CompletionRecapItem extends StatelessWidget {
  final String title;
  final bool   done;
  final Color  primary;
  const _CompletionRecapItem({
    required this.title,
    required this.done,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done
              ? primary.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: done ? primary : AppColors.inkSoft.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.firaSansCondensed(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: done ? AppColors.ink : AppColors.inkSoft,
                  height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

