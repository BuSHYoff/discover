import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/features/journey/widgets/step_shell.dart';
import 'package:discover/features/journey/widgets/counter_badge.dart';
import 'package:discover/core/theme/app_theme.dart';

class MaterialsStep extends StatelessWidget {
  final List<AIMaterial> materials;
  final List<bool> checked;
  final ValueChanged<int> onToggle;

  const MaterialsStep({
    super.key,
    required this.materials,
    required this.checked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final doneCount = checked.where((c) => c).length;
    final allDone   = materials.isNotEmpty && doneCount == materials.length;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
    return StepShell(
      icon: Icons.shopping_bag_outlined,
      title: 'Matériel requis',
      subtitle: 'Coche chaque élément au fur et à mesure que tu t\'équipes.',
      badge: CounterBadge(done: doneCount, total: materials.length, label: 'articles'),
      body: Column(children: [
        ...materials.asMap().entries.map((entry) {
          final i = entry.key; final m = entry.value;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onToggle(i); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: checked[i] ? primaryLight : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: checked[i]
                    ? primary.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.07)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: checked[i] ? primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: checked[i] ? primary : Colors.black.withValues(alpha: 0.15),
                        width: 1.5),
                  ),
                  child: checked[i]
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.name, style: GoogleFonts.firaSansCondensed(
                      fontSize: 13.5, fontWeight: FontWeight.w600,
                      color: checked[i] ? primary : AppColors.ink,
                      decoration: checked[i] ? TextDecoration.lineThrough : null,
                      decorationColor: primary.withValues(alpha: 0.5))),
                  if (m.note.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(m.note, style: GoogleFonts.firaSansCondensed(
                        fontSize: 12, height: 1.4, color: AppColors.inkSoft)),
                  ],
                ])),
              ]),
            ),
          );
        }),
        if (allDone) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
                color: primaryLight, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primary.withValues(alpha: 0.2))),
            child: Row(children: [
              Icon(Icons.check_circle_rounded, color: primary, size: 20),
              const SizedBox(width: 10),
              Text('Tu es prêt(e) à commencer !', style: GoogleFonts.firaSansCondensed(
                  fontSize: 13.5, fontWeight: FontWeight.w600, color: primary)),
            ]),
          ),
        ],
      ]),
    );
  }
}

