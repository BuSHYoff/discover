import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:discover/core/models/passion.dart';
import 'package:discover/core/services/passions_service.dart';
import 'package:discover/core/theme/app_theme.dart';
import 'package:discover/features/home/screens/community_screen.dart';
import 'package:discover/features/home/screens/create_post_screen.dart';
import 'package:discover/features/home/screens/detail_screen.dart';
import 'package:discover/features/journey/widgets/confetti_overlay.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COMPLETION SCREEN — Page de fin de parcours.
//
// Affichée quand l'utilisateur tape sur l'étape finale "Partager" du parcours.
// Contient :
//   1. Félicitations (titre + sous-titre + confetti GIF qui pop)
//   2. CTA "Voir les créations"      → CommunityScreen
//   3. CTA "Partager ma création"    → CreatePostScreen
//   4. Suggestions d'autres passions de la même catégorie
//
// Plein écran (Navigator.push), pas une bottom sheet — l'utilisateur a fini
// un parcours, c'est un moment marquant qui mérite l'écran complet.
// ─────────────────────────────────────────────────────────────────────────────

class CompletionScreen extends StatefulWidget {
  final Passion passion;
  const CompletionScreen({super.key, required this.passion});

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen> {
  @override
  void initState() {
    super.initState();
    // Confetti dès l'arrivée sur l'écran, après le 1er frame pour que
    // l'overlay ait un Navigator parent prêt à le recevoir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        HapticFeedback.mediumImpact();
        ConfettiOverlay.show(context, duration: const Duration(seconds: 4));
      }
    });
  }

  /// Liste des suggestions : autres passions de la même catégorie, max 3.
  /// L'ordre du backend (alphabétique) est conservé.
  List<Passion> get _suggestions {
    return PassionsService.cached
        .where((p) => p.id != widget.passion.id
                   && p.category == widget.passion.category)
        .take(3)
        .toList();
  }

  void _openCommunity() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CommunityScreen(passion: widget.passion),
    ));
  }

  void _openPublish() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreatePostScreen(passion: widget.passion),
    ));
  }

  void _openSuggestion(Passion p) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DetailScreen(passion: p),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final primary    = Theme.of(context).colorScheme.primary;
    final topPadding = MediaQuery.of(context).padding.top;
    final suggestions = _suggestions;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          // ── App bar : croix de fermeture en haut à gauche ───────────
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8)],
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Bloc Félicitations ────────────────────────────────
                  _CongratsBlock(passionName: widget.passion.name, primary: primary),
                  const SizedBox(height: 28),

                  // ── CTA principal : Voir les créations ───────────────
                  _PrimaryCta(
                    primary:    primary,
                    icon:       Icons.photo_library_outlined,
                    title:      'Voir les créations',
                    subtitle:   'Photos, likes & commentaires de la communauté',
                    onTap:      _openCommunity,
                  ),
                  const SizedBox(height: 12),

                  // ── CTA secondaire : Partager ma création ────────────
                  _SecondaryCta(
                    primary:  primary,
                    icon:     Icons.add_a_photo_outlined,
                    title:    'Partager ma création',
                    subtitle: 'Publie une photo de ta progression',
                    onTap:    _openPublish,
                  ),
                  const SizedBox(height: 28),

                  // ── Suggestions ──────────────────────────────────────
                  if (suggestions.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.bolt_rounded, color: primary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Tu pourrais aussi aimer',
                          style: GoogleFonts.firaSansCondensed(
                              fontSize: 17, fontWeight: FontWeight.w800,
                              color: AppColors.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'D\'autres passions dans la même catégorie : ${widget.passion.category}.',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 13, color: AppColors.inkSoft, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children: suggestions
                          .map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _SuggestionTile(
                                  passion: p,
                                  primary: primary,
                                  onTap:   () => _openSuggestion(p),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _CongratsBlock extends StatelessWidget {
  final String passionName;
  final Color  primary;
  const _CongratsBlock({required this.passionName, required this.primary});

  // Palette dorée fixe pour le bloc de félicitations — cohérent avec le
  // trophée final débloqué (gold doré) sur la timeline. La couleur primary
  // du user n'est plus utilisée ici, le doré reste universel quel que soit
  // le thème choisi.
  static const Color _goldLight = Color(0xFFFFF4D6); // dégradé top
  static const Color _goldDeep  = Color(0xFFFFE9A8); // dégradé bottom
  static const Color _goldEdge  = Color(0xFFD4A93A); // bordure

  @override
  Widget build(BuildContext context) {
    // primary n'est plus utilisé visuellement ici — on garde le param pour
    // conserver l'API du widget au cas où on veuille le mixer plus tard.
    // ignore: unused_local_variable
    final _ = primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [_goldLight, _goldDeep],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _goldEdge.withValues(alpha: 0.45)),
        boxShadow: [BoxShadow(
            color: _goldEdge.withValues(alpha: 0.15),
            blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          // GIF reward animé (remplace l'icône trophée statique)
          SizedBox(
            width: 120, height: 120,
            child: Image.asset(
              'assets/images/reward.gif',
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bravo !',
            style: GoogleFonts.firaSansCondensed(
                fontSize: 32, fontWeight: FontWeight.w900,
                color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            'Tu as complété "$passionName".',
            textAlign: TextAlign.center,
            style: GoogleFonts.firaSansCondensed(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            'Si ça t\'a plu, explore d\'autres activités qui pourraient te plaire.',
            textAlign: TextAlign.center,
            style: GoogleFonts.firaSansCondensed(
                fontSize: 13, color: AppColors.inkSoft, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  final Color        primary;
  final IconData     icon;
  final String       title;
  final String       subtitle;
  final VoidCallback onTap;
  const _PrimaryCta({
    required this.primary,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: primary.withValues(alpha: 0.28),
              blurRadius: 18, offset: const Offset(0, 7))],
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85))),
              ]),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.white.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

class _SecondaryCta extends StatelessWidget {
  final Color        primary;
  final IconData     icon;
  final String       title;
  final String       subtitle;
  final VoidCallback onTap;
  const _SecondaryCta({
    required this.primary,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryLight = Color.lerp(primary, Colors.white, 0.85)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primary.withValues(alpha: 0.18)),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 12, color: AppColors.inkSoft)),
              ]),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppColors.ink.withValues(alpha: 0.30)),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final Passion      passion;
  final Color        primary;
  final VoidCallback onTap;
  const _SuggestionTile({
    required this.passion,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryLight = Color.lerp(primary, Colors.white, 0.88)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 56, height: 56,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: passion.imageUrl.isNotEmpty
                  ? Image.network(
                      passion.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.image_outlined, color: primary, size: 24),
                    )
                  : Icon(Icons.image_outlined, color: primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(passion.name,
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(passion.tagline,
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 12, color: AppColors.inkSoft, height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: AppColors.inkSoft.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
