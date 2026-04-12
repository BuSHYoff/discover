import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/features/journey/widgets/journey_progress.dart';
import 'package:discover/core/theme/app_theme.dart';

class ProgressCard extends StatelessWidget {
  final JourneyProgress progress;
  final VoidCallback onTap;

  const ProgressCard({super.key, required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct   = progress.globalPercentInt;
    final steps = progress.steps;
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 38, height: 38,
                decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(11)),
                child: Center(child: Text('$pct%', style: GoogleFonts.firaSansCondensed(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ma progression', style: GoogleFonts.firaSansCondensed(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
              Text('${JourneyProgress.stepNames[progress.currentStep.clamp(0, 3)]} · étape ${progress.currentStep + 1}/4',
                  style: GoogleFonts.firaSansCondensed(fontSize: 11.5, color: AppColors.inkSoft)),
            ])),
            Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft.withValues(alpha: 0.4), size: 18),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Container(height: 6, color: primary.withValues(alpha: 0.1),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft, widthFactor: progress.globalPercent,
                    child: Container(decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(100))),
                  )),
            )),
            const SizedBox(width: 10),
            Text('$pct%', style: GoogleFonts.firaSansCondensed(fontSize: 12, fontWeight: FontWeight.w700, color: primary)),
          ]),
          const SizedBox(height: 14),
          Row(
            children: steps.asMap().entries.map((entry) {
              final i = entry.key; final step = entry.value;
              final isActive = i == progress.currentStep;
              return Expanded(child: Padding(
                padding: EdgeInsets.only(right: i < steps.length - 1 ? 4 : 0),
                child: Column(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(100),
                      child: Container(height: 4, color: primary.withValues(alpha: 0.1),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft, widthFactor: step.percent,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              decoration: BoxDecoration(
                                color: step.isComplete ? primary : isActive ? primary.withValues(alpha: 0.6) : primary.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ))),
                  const SizedBox(height: 4),
                  Icon(step.iconData, size: isActive ? 13 : 11,
                      color: step.isComplete ? primary : isActive ? primary : primary.withValues(alpha: 0.4)),
                ]),
              ));
            }).toList(),
          ),
        ]),
      ),
    );
  }
}
