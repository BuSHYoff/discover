import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

class DropCapText extends StatefulWidget {
  final String text;
  final String? tagline;
  final Widget? rightWidget;

  const DropCapText({super.key, required this.text, this.tagline, this.rightWidget});

  @override
  State<DropCapText> createState() => _DropCapTextState();
}

class _DropCapTextState extends State<DropCapText> {
  bool _expanded = false;

  (String, String) _splitFirstSentence(String text) {
    final match = RegExp(r'^(.+?[.!?])\s+(.+)$', dotAll: true).firstMatch(text);
    if (match != null) return (match.group(1)!, match.group(2)!);
    return (text, '');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty && (widget.tagline == null || widget.tagline!.isEmpty)) {
      return const SizedBox.shrink();
    }
    final primary = Theme.of(context).colorScheme.primary;

    // Si une tagline est fournie : elle est le titre en gras, le texte complet est le corps
    final bool hasTagline = widget.tagline != null && widget.tagline!.isNotEmpty;
    final String firstSentence = hasTagline ? widget.tagline! : _splitFirstSentence(widget.text).$1;
    final String rest          = hasTagline ? widget.text      : _splitFirstSentence(widget.text).$2;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: primary, width: 3),
        ),
      ),
      padding: const EdgeInsets.only(left: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── "À PROPOS" + firstSentence side-by-side with optional rightWidget ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'À PROPOS',
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: primary,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        firstSentence,
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 16,
                          height: 1.6,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.rightWidget != null) ...[
                  const SizedBox(width: 12),
                  widget.rightWidget!,
                ],
              ],
            ),
            if (rest.isNotEmpty) ...[
              const SizedBox(height: 6),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Text(
                  rest,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.firaSansCondensed(
                    fontSize: 15,
                    height: 1.7,
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                secondChild: Text(
                  rest,
                  style: GoogleFonts.firaSansCondensed(
                    fontSize: 15,
                    height: 1.7,
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded ? 'Voir moins' : 'Voir plus',
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
      ]),
    );
  }
}
