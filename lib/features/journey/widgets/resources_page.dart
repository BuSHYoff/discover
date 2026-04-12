import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/features/home/screens/detail_screen.dart';
import 'package:discover/core/utils/url_utils.dart';
import 'package:discover/core/theme/app_theme.dart';

class ResourcesPage extends StatefulWidget {
  final Passion passion;
  const ResourcesPage({super.key, required this.passion});

  @override
  State<ResourcesPage> createState() => _RessourcesPageState();
}

class _RessourcesPageState extends State<ResourcesPage> {
  AIContent? _content;
  bool _loading = true;

  static const _typeIconData = <String, IconData>{
    'youtube':  Icons.play_circle_outline_rounded,
    'figure':   Icons.person_outline_rounded,
    'livre':    Icons.auto_stories_outlined,
    'site_web': Icons.language_rounded,
  };
  static const _typeColors = <String, Color>{
    'youtube':  Color(0xFFE8A090),
    'figure':   Color(0xFF90CAF9),
    'livre':    Color(0xFFF0C070),
    'site_web': Color(0xFFA8C5B0),
  };
  static const _typeLabels = <String, String>{
    'youtube':  'YouTube',
    'figure':   'Personnalité',
    'livre':    'Livre',
    'site_web': 'Site web',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await AIContentProvider.getFor(widget.passion.id);
    if (mounted) setState(() { _content = c; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(children: [
        Container(
          padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pour aller plus loin',
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text(widget.passion.name,
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 12, color: AppColors.inkSoft)),
              ]),
            ),
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: primaryLight, shape: BoxShape.circle),
              child: Icon(Icons.menu_book_outlined,
                  color: primary, size: 20),
            ),
          ]),
        ),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: primary, strokeWidth: 2))
              : _content == null
              ? Center(child: Text('Contenu indisponible',
              style: GoogleFonts.firaSansCondensed(color: AppColors.inkSoft)))
              : ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'Les meilleures ressources pour progresser rapidement en ${widget.passion.name}.',
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 14, color: AppColors.inkSoft, height: 1.5),
              ),
              const SizedBox(height: 20),
              ..._content!.resources.map((r) {
                final color    = _typeColors[r.type]   ?? const Color(0xFFA8C5B0);
                final iconData = _typeIconData[r.type] ?? Icons.link_rounded;
                final canOpen = r.url.trim().isNotEmpty;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: canOpen ? () => launchExternalUrl(context, r.url) : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(iconData, size: 20, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.title, style: GoogleFonts.firaSansCondensed(
                                  fontSize: 13.5, fontWeight: FontWeight.w600,
                                  color: AppColors.ink)),
                              const SizedBox(height: 3),
                              Text(r.detail, style: GoogleFonts.firaSansCondensed(
                                  fontSize: 12, height: 1.4, color: AppColors.inkSoft)),
                              if (canOpen) ...[
                                const SizedBox(height: 6),
                                Row(children: [
                                  Icon(Icons.open_in_new_rounded, size: 12, color: primary.withValues(alpha: 0.8)),
                                  const SizedBox(width: 4),
                                  Text('Ouvrir la ressource', style: GoogleFonts.firaSansCondensed(
                                      fontSize: 11, color: primary.withValues(alpha: 0.85))),
                                ]),
                              ],
                            ])),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(100)),
                          child: Text(_typeLabels[r.type] ?? r.type,
                              style: GoogleFonts.firaSansCondensed(
                                  fontSize: 10, fontWeight: FontWeight.w600,
                                  color: AppColors.ink.withValues(alpha: 0.5))),
                        ),
                      ]),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ]),
    );
  }
}
