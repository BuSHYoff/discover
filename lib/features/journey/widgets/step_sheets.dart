import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';
import 'package:discover/core/models/passion.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:discover/core/utils/url_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MATERIALS SHEET — Bottom sheet pour l'étape matériel
// ─────────────────────────────────────────────────────────────────────────────

class MaterialsSheet extends StatefulWidget {
  final List<AIMaterial>           materials;
  final String                     passionName;
  final List<bool>                 initialChecked;
  final Future<void> Function(int idx, bool value) onToggleItem;
  /// Appelé quand l'user valide l'étape complète. Doit retourner les XP gagnés
  /// pour la complétion finale (ex: bonus). Le sheet se ferme automatiquement.
  final Future<int> Function() onValidate;

  const MaterialsSheet({
    super.key,
    required this.materials,
    required this.passionName,
    required this.initialChecked,
    required this.onToggleItem,
    required this.onValidate,
  });

  static Future<void> show(BuildContext context, {
    required List<AIMaterial> materials,
    required String passionName,
    required List<bool> initialChecked,
    required Future<void> Function(int idx, bool value) onToggleItem,
    required Future<int> Function() onValidate,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MaterialsSheet(
        materials: materials,
        passionName: passionName,
        initialChecked: initialChecked,
        onToggleItem: onToggleItem,
        onValidate: onValidate,
      ),
    );
  }

  @override
  State<MaterialsSheet> createState() => _MaterialsSheetState();
}

class _MaterialsSheetState extends State<MaterialsSheet> {
  late List<bool> _checked;
  bool _validating = false;

  @override
  void initState() {
    super.initState();
    _checked = List.of(widget.initialChecked);
    if (_checked.length != widget.materials.length) {
      _checked = List.filled(widget.materials.length, false);
    }
  }

  bool get _allChecked =>
      _checked.isNotEmpty && _checked.every((v) => v);

  void _showNoteDialog(BuildContext context, String name, String note) {
    final primary = Theme.of(context).colorScheme.primary;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Expanded(child: Text(name,
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppColors.ink))),
              ]),
              const SizedBox(height: 10),
              Text(note,
                  style: GoogleFonts.firaSansCondensed(
                      fontSize: 13, color: AppColors.inkSoft, height: 1.5)),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('OK',
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 13, fontWeight: FontWeight.w700, color: primary)),
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.85)!;
    final doneCount = _checked.where((c) => c).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          color: AppColors.cream,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  )),
              const SizedBox(height: 18),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.shopping_bag_outlined, color: primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Matériel requis',
                              style: GoogleFonts.firaSansCondensed(
                                  fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          Text(
                            '$doneCount / ${widget.materials.length} cochés',
                            style: GoogleFonts.firaSansCondensed(
                                fontSize: 12, color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Coche chaque élément à mesure que tu te procures le matériel.',
                  style: GoogleFonts.firaSansCondensed(
                      fontSize: 12, color: AppColors.inkSoft, height: 1.4),
                ),
              ),
              const SizedBox(height: 14),
              // Liste
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: widget.materials.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final m = widget.materials[i];
                    final isChecked = _checked[i];
                    return GestureDetector(
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        setState(() => _checked[i] = !_checked[i]);
                        await widget.onToggleItem(i, _checked[i]);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isChecked ? primaryLight : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isChecked
                                ? primary.withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.07),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Checkbox
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                color: isChecked ? primary : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isChecked ? primary : Colors.black.withValues(alpha: 0.15),
                                  width: 1.5,
                                ),
                              ),
                              child: isChecked
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            // Titre
                            Expanded(
                              child: Text(m.name,
                                  style: GoogleFonts.firaSansCondensed(
                                    fontSize: 14, fontWeight: FontWeight.w600,
                                    color: isChecked ? primary : AppColors.ink,
                                    decoration: isChecked ? TextDecoration.lineThrough : null,
                                    decorationColor: primary.withValues(alpha: 0.5),
                                  )),
                            ),
                            const SizedBox(width: 10),
                            // ℹ️ Info (si description disponible)
                            if (m.note.isNotEmpty)
                              GestureDetector(
                                onTap: () => _showNoteDialog(context, m.name, m.note),
                                child: Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.10),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.info_outline_rounded,
                                      size: 16, color: Color(0xFF3B82F6)),
                                ),
                              ),
                            const SizedBox(width: 8),
                            // 🛒 Amazon
                            GestureDetector(
                              onTap: () => launchUrl(
                                buildAmazonSearchUri(widget.passionName, m.name),
                                mode: LaunchMode.inAppBrowserView,
                              ),
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9900).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFFF9900).withValues(alpha: 0.4)),
                                ),
                                child: const Icon(Icons.shopping_cart_outlined,
                                    size: 15, color: Color(0xFFCC7A00)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // CTA
              Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding + 24),
                child: GestureDetector(
                  onTap: !_allChecked || _validating ? null : () async {
                    setState(() => _validating = true);
                    HapticFeedback.mediumImpact();
                    await widget.onValidate();
                    // ignore: use_build_context_synchronously
                    if (mounted) Navigator.pop(context);
                  },
                  child: Opacity(
                    opacity: _allChecked ? 1.0 : 0.4,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _allChecked ? [BoxShadow(
                            color: primary.withValues(alpha: 0.3),
                            blurRadius: 16, offset: const Offset(0, 6))] : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _allChecked
                            ? 'Valider l\'étape'
                            : 'Coche tous les items pour valider',
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DAILY STEP SHEET — Bottom sheet pour une étape journalière (Jour N)
// ─────────────────────────────────────────────────────────────────────────────

class DailyStepSheet extends StatelessWidget {
  final int    dayNumber;
  final PassionStep step;
  final bool   alreadyDone;
  final Future<void> Function() onComplete;

  const DailyStepSheet({
    super.key,
    required this.dayNumber,
    required this.step,
    required this.alreadyDone,
    required this.onComplete,
  });

  static Future<void> show(BuildContext context, {
    required int dayNumber,
    required PassionStep step,
    required bool alreadyDone,
    required Future<void> Function() onComplete,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DailyStepSheet(
        dayNumber:   dayNumber,
        step:        step,
        alreadyDone: alreadyDone,
        onComplete:  onComplete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final primary = Theme.of(context).colorScheme.primary;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        color: AppColors.cream,
        padding: EdgeInsets.fromLTRB(24, 14, 24, bottomPadding + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  )),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: Text('J$dayNumber',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jour $dayNumber',
                          style: GoogleFonts.firaSansCondensed(
                              fontSize: 11, color: AppColors.inkSoft, letterSpacing: 1.2,
                              fontWeight: FontWeight.w600)),
                      Text(step.title,
                          style: GoogleFonts.firaSansCondensed(
                              fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (step.details.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: Text(
                  step.details,
                  style: GoogleFonts.firaSansCondensed(
                      fontSize: 14, color: AppColors.ink, height: 1.55),
                ),
              ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: alreadyDone ? null : () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                await onComplete();
              },
              child: Opacity(
                opacity: alreadyDone ? 0.5 : 1.0,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
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
                      Icon(alreadyDone ? Icons.check_circle_rounded : Icons.flag_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(alreadyDone ? 'Déjà complété' : 'J\'ai complété cette étape',
                          style: GoogleFonts.firaSansCondensed(
                              fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
