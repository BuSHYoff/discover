import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/features/home/screens/detail_screen.dart';
import 'package:discover/features/journey/widgets/journey_progress.dart';
import 'package:discover/features/journey/widgets/step_shell.dart';
import 'package:discover/features/journey/widgets/materials_step.dart';
import 'package:discover/features/journey/widgets/this_week_step.dart';
import 'package:discover/features/journey/widgets/share_step.dart';
import 'package:discover/features/journey/widgets/tips_page.dart';
import 'package:discover/features/journey/widgets/resources_page.dart';
import 'package:discover/features/journey/widgets/counter_badge.dart';
import 'package:discover/features/journey/widgets/check_item.dart';
import 'package:discover/features/journey/widgets/next_button.dart';
import 'package:discover/core/theme/app_theme.dart';

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

class _JourneyScreenState extends State<JourneyScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentStep = 0;

  AIContent? _aiContent;
  bool _aiLoading = true;

  // Étape 1 : Matériel
  List<bool> _materialsChecked     = [];
  // Étape 2 : Cette semaine
  List<bool> _thisWeekChecked = [];
  // Étape 3 : Partager (pas de checklist)

  bool _showStepError = false;

  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  // 3 étapes seulement (Matériel, Cette week, Partager)
  static const int _totalSteps = 3;

  static const _stepTitles = [
    'Matériel', 'Cette semaine', 'Partager',
  ];

  static const _stepIcons = [
    Icons.shopping_bag_outlined,
    Icons.rocket_launch_outlined,
    Icons.diversity_3_rounded,
  ];

  JourneyProgress get _prog => widget.progress;

  @override
  void initState() {
    super.initState();
    _currentStep = _prog.currentStep.clamp(0, _totalSteps - 1);
    _pageController = PageController(initialPage: _currentStep);

    final initialTarget = (_currentStep + 1) / _totalSteps;
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _progressAnim = Tween<double>(begin: initialTarget, end: initialTarget)
        .animate(CurvedAnimation(
        parent: _progressCtrl, curve: Curves.easeOutCubic));

    _loadAIContent();
  }

  Future<void> _loadAIContent() async {
    final content = await AIContentProvider.getFor(widget.passion.id);
    if (!mounted) return;
    setState(() {
      _aiContent = content;
      _aiLoading = false;
      if (content != null) {
        // Matériel
        _materialsChecked = _prog.materialsChecked.isNotEmpty
            ? List.of(_prog.materialsChecked)
            : List.filled(content.materials.length, false);
        // Cette semaine
        _thisWeekChecked = _prog.thisWeekChecked.isNotEmpty
            ? List.of(_prog.thisWeekChecked)
            : List.filled(content.steps.length, false);

        _prog.initTotals(
          thisWeek: content.steps.length,
          materials:     content.materials.length,
        );
        _prog.updateCounts(
          thisWeek: _thisWeekChecked,
          materials:     _materialsChecked,
        );

        if (_prog.currentStep < 0) {
          _prog.updateStep(0);
          _currentStep = 0;
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  void _notifyProgress() {
    _prog.updateCounts(
      thisWeek: _thisWeekChecked,
      materials:     _materialsChecked,
    );
    if (_showStepError && _isCurrentStepComplete()) {
      setState(() => _showStepError = false);
    }
  }

  String _stepErrorMessage() {
    final remaining = _currentStep == 0
        ? _materialsChecked.where((v) => !v).length
        : _thisWeekChecked.where((v) => !v).length;
    return 'Il te reste $remaining élément${remaining > 1 ? 's' : ''} à cocher avant de continuer.';
  }

  bool _isCurrentStepComplete() {
    switch (_currentStep) {
      case 0: return _materialsChecked.isNotEmpty && _materialsChecked.every((v) => v);
      case 1: return _thisWeekChecked.isNotEmpty && _thisWeekChecked.every((v) => v);
      case 2: return true; // Étape Partager : toujours valide
      default: return true;
    }
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    HapticFeedback.lightImpact();
    final target = (step + 1) / _totalSteps;
    _progressAnim = Tween<double>(
      begin: _progressAnim.value,
      end: target,
    ).animate(CurvedAnimation(
        parent: _progressCtrl, curve: Curves.easeOutCubic));
    _progressCtrl.forward(from: 0);
    setState(() {
      _currentStep = step;
      _showStepError = false;
    });
    _prog.updateStep(step);
    _pageController.animateToPage(step,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic);
  }

  void _next() {
    if (!_isCurrentStepComplete()) {
      HapticFeedback.mediumImpact();
      setState(() => _showStepError = true);
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    } else {
      // Dernière étape → "J'ai terminé !"
      HapticFeedback.mediumImpact();
      widget.progress.syncToFirestore();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.celebration_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text('Bravo ! Tu as terminé ${widget.passion.name} !',
              style: GoogleFonts.firaSansCondensed()),
        ]),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  /// Ouvre la page Secrets depuis le header
  void _openSecrets() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TipsPage(passion: widget.passion),
    ));
  }

  /// Ouvre la page Ressources depuis le header
  void _openRessources() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResourcesPage(passion: widget.passion),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding    = MediaQuery.of(context).padding.top;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;

    if (_aiLoading) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircularProgressIndicator(color: primary, strokeWidth: 2),
            const SizedBox(height: 16),
            Text('Chargement de ton programme…',
                style: GoogleFonts.firaSansCondensed(fontSize: 14, color: AppColors.inkSoft)),
          ]),
        ),
      );
    }

    if (_aiContent == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Center(
            child: Padding(
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
                    decoration: BoxDecoration(
                        color: primary, borderRadius: BorderRadius.circular(14)),
                    child: Text('Retour',
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
    }

    final c = _aiContent!;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(children: [
        // ── HEADER ──────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // Bouton retour / fermer
              GestureDetector(
                onTap: () {
                  widget.progress.syncToFirestore();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.close_rounded, size: 16, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 14),
              // Titre + étape
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.passion.name,
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  Text(
                    '${_stepTitles[_currentStep]}  ·  ${_currentStep + 1} / $_totalSteps',
                    style: GoogleFonts.firaSansCondensed(fontSize: 12, color: AppColors.inkSoft),
                  ),
                ]),
              ),
              // ── Bouton Ressources ──
              GestureDetector(
                onTap: _openRessources,
                child: Container(
                  width: 38, height: 38,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                  ),
                  child: Icon(Icons.menu_book_outlined,
                      size: 17, color: primary),
                ),
              ),
              // ── Bouton Ampoule / Secrets ──
              GestureDetector(
                onTap: _openSecrets,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: primary.withValues(alpha: 0.2)),
                  ),
                  child: Icon(Icons.lightbulb_outline_rounded,
                      size: 17, color: primary),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Container(
                height: 4,
                color: primary.withValues(alpha: 0.1),
                child: AnimatedBuilder(
                  animation: _progressAnim,
                  builder: (_, __) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progressAnim.value,
                    child: Container(
                      decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(100)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Dots de progression
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalSteps, (i) {
                final isActive = i == _currentStep;
                final isDone   = i < _currentStep;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isDone || isActive
                        ? primary
                        : primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 5, color: Colors.white)
                      : null,
                );
              }),
            ),
          ]),
        ),

        // ── PAGES ───────────────────────────────────────────
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Étape 1 : Matériel
              MaterialsStep(
                materials: c.materials,
                totalBudget: c.totalBudget,
                checked: _materialsChecked,
                onToggle: (i) {
                  setState(() => _materialsChecked[i] = !_materialsChecked[i]);
                  _notifyProgress();
                },
              ),
              // Étape 2 : Cette week
              ThisWeekStep(
                steps: c.steps,
                checked: _thisWeekChecked,
                onToggle: (i) {
                  setState(() => _thisWeekChecked[i] = !_thisWeekChecked[i]);
                  _notifyProgress();
                },
              ),
              // Étape 3 : Partager
              ShareStep(passion: widget.passion),
            ],
          ),
        ),

        // ── CTA ─────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: _showStepError
                    ? Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.errorSoft
                            .withValues(alpha: 0.5)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.errorDark, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _stepErrorMessage(),
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 13,
                            color: AppColors.errorDark,
                            fontWeight: FontWeight.w500,
                            height: 1.4),
                      ),
                    ),
                  ]),
                )
                    : const SizedBox.shrink(),
              ),
              Row(
                children: [
                  // Bouton retour (caché sur la première étape)
                  if (_currentStep > 0) ...[
                    GestureDetector(
                      onTap: () => _goToStep(_currentStep - 1),
                      child: Container(
                        width: 52, height: 52,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.black.withValues(alpha: 0.07)),
                          boxShadow: [BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8)],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: AppColors.ink),
                      ),
                    ),
                  ],
                  Expanded(
                    child: NextButton(
                      label: _currentStep < _totalSteps - 1
                          ? 'Étape suivante'
                          : 'J\'ai terminé !',
                      isLast: _currentStep == _totalSteps - 1,
                      enabled: _isCurrentStepComplete(),
                      onTap: _next,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
