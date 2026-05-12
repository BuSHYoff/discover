import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/core/theme/app_theme.dart';

class TipsPage extends StatefulWidget {
  final Passion passion;
  const TipsPage({super.key, required this.passion});

  @override
  State<TipsPage> createState() => _SecretsPageState();
}

class _SecretsPageState extends State<TipsPage> {
  AIContent? _content;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bon à savoir', style: GoogleFonts.firaSansCondensed(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
              Text(widget.passion.name, style: GoogleFonts.firaSansCondensed(fontSize: 12, color: AppColors.inkSoft)),
            ])),
            Container(width: 40, height: 40,
                decoration: BoxDecoration(color: primaryLight, shape: BoxShape.circle),
                child: Icon(Icons.lightbulb_outline_rounded, color: primary, size: 20)),
          ]),
        ),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: primary, strokeWidth: 2))
              : _content == null
              ? Center(child: Text('Contenu indisponible', style: GoogleFonts.firaSansCondensed(color: AppColors.inkSoft)))
              : ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: primaryLight, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primary.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Icon(Icons.tips_and_updates_outlined, color: primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    'Ce que les débutants ignorent et qui fait toute la différence.',
                    style: GoogleFonts.firaSansCondensed(fontSize: 13.5, color: primary, fontWeight: FontWeight.w500, height: 1.4),
                  )),
                ]),
              ),
              ..._content!.tips.asMap().entries.map((entry) {
                final i = entry.key; final s = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 32, height: 32,
                        decoration: BoxDecoration(color: primaryLight, borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text('${i + 1}', style: GoogleFonts.firaSansCondensed(fontSize: 13, fontWeight: FontWeight.w700, color: primary)))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(s, style: GoogleFonts.firaSansCondensed(fontSize: 14, height: 1.55, color: AppColors.ink))),
                  ]),
                );
              }),
            ],
          ),
        ),
      ]),
    );
  }
}
