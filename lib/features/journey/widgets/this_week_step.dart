import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/features/journey/widgets/step_shell.dart';
import 'package:discover/features/journey/widgets/counter_badge.dart';
import 'package:discover/core/theme/app_theme.dart';

class ThisWeekStep extends StatelessWidget {
  final List<PassionStep> steps;
  final List<bool> checked;
  final ValueChanged<int> onToggle;

  const ThisWeekStep({
    super.key,
    required this.steps,
    required this.checked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final doneCount = checked.where((c) => c).length;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
    return StepShell(
      icon: Icons.rocket_launch_outlined,
      title: 'Cette semaine',
      subtitle: 'Suis ces étapes dans l\'ordre pour bien démarrer ta pratique.',
      badge: CounterBadge(done: doneCount, total: steps.length, label: 'étapes'),
      body: Column(
        children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final isLast    = i == steps.length - 1;
          final isDone    = checked[i];
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onToggle(i); },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Colonne numéro + ligne ──────────────────────
                Column(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: isDone ? primary : primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 15)
                          : Text('${i + 1}',
                          style: GoogleFonts.firaSansCondensed(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: primary)),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 36,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: primary.withValues(alpha: 0.12),
                    ),
                ]),
                const SizedBox(width: 12),
                // ── Carte titre + details ───────────────────────
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 10, top: 2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDone ? primaryLight : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDone
                              ? primary.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.07),
                        ),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: isDone ? 0.0 : 0.03),
                            blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            style: GoogleFonts.firaSansCondensed(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDone ? primary : AppColors.ink,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                                decorationColor: primary.withValues(alpha: 0.4)),
                          ),
                          if (s.details.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              s.details,
                              style: GoogleFonts.firaSansCondensed(
                                  fontSize: 12.5,
                                  height: 1.5,
                                  color: isDone
                                      ? primary.withValues(alpha: 0.7)
                                      : AppColors.inkSoft),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
