import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/features/journey/widgets/journey_progress.dart';
import 'package:discover/features/home/widgets/step_badge.dart';
import 'package:discover/core/theme/app_theme.dart';

class ProgressSheet extends StatelessWidget {
  final JourneyProgress progress;
  final Passion passion;

  const ProgressSheet({super.key, required this.progress, required this.passion});

  @override
  Widget build(BuildContext context) {
    final steps = progress.steps;
    final pct   = progress.globalPercentInt;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.72, minChildSize: 0.4, maxChildSize: 0.92,
      builder: (context, scrollCtrl) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          color: AppColors.cream,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(children: [
                Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100))),
                const SizedBox(height: 20),
                Row(children: [
                  Container(width: 44, height: 44,
                      decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(13)),
                      child: Center(child: Text('$pct%', style: GoogleFonts.firaSansCondensed(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)))),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Ma progression · ${passion.name}', style: GoogleFonts.firaSansCondensed(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    Text(progress.currentStep >= 0
                        ? 'En cours : ${JourneyProgress.stepNames[progress.currentStep.clamp(0, 3)]}'
                        : 'Pas encore commencé',
                        style: GoogleFonts.firaSansCondensed(fontSize: 12, color: AppColors.inkSoft)),
                  ])),
                ]),
                const SizedBox(height: 16),
                ClipRRect(borderRadius: BorderRadius.circular(100),
                    child: Container(height: 8, color: primary.withValues(alpha: 0.1),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft, widthFactor: progress.globalPercent,
                          child: Container(decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(100))),
                        ))),
                const SizedBox(height: 16),
                Container(height: 1, color: Colors.black.withValues(alpha: 0.06)),
              ]),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: steps.asMap().entries.map((entry) {
                  final i = entry.key; final step = entry.value;
                  final isActive = i == progress.currentStep;
                  final isDone = step.isComplete;
                  final isLocked = !step.isStarted && !isActive && i > (progress.currentStep < 0 ? -1 : progress.currentStep);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDone ? primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDone ? primary.withValues(alpha: 0.25) : isActive ? primary.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.06),
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Container(width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: isDone ? primary : isActive ? primaryLight : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: isDone
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                              : Icon(step.iconData, size: 18,
                              color: isLocked ? AppColors.inkSoft.withValues(alpha: 0.5) : isActive ? primary : AppColors.inkSoft))),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(step.name, style: GoogleFonts.firaSansCondensed(fontSize: 14, fontWeight: FontWeight.w700, color: isLocked ? AppColors.inkSoft : AppColors.ink))),
                          if (isActive) StepBadge('En cours', primary, Colors.white),
                          if (isDone) StepBadge('Terminé', primary.withValues(alpha: 0.12), primary),
                        ]),
                        const SizedBox(height: 5),
                        if (!isLocked && step.total > 1)
                          Row(children: [
                            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(100),
                                child: Container(height: 4, color: primary.withValues(alpha: 0.1),
                                    child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: step.percent,
                                        child: Container(color: primary))))),
                            const SizedBox(width: 8),
                            Text('${step.done}/${step.total}', style: GoogleFonts.firaSansCondensed(fontSize: 11, color: AppColors.inkSoft, fontWeight: FontWeight.w500)),
                          ])
                        else
                          Text(
                            isLocked ? 'Pas encore atteint' : isDone ? 'Section complétée ✓' : isActive ? 'En cours de lecture' : 'À explorer',
                            style: GoogleFonts.firaSansCondensed(fontSize: 11.5, color: AppColors.inkSoft),
                          ),
                      ])),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
