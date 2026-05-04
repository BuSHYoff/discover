import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/features/home/services/youtube_service.dart';
import 'package:discover/features/home/screens/shorts_player_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHORTS ROW — 3 cards + "Voir plus" → ShortsPlayerScreen TikTok-style
// ─────────────────────────────────────────────────────────────────────────────

class ShortsRow extends StatefulWidget {
  final Passion passion;

  const ShortsRow({super.key, required this.passion});

  @override
  State<ShortsRow> createState() => _ShortsRowState();
}

class _ShortsRowState extends State<ShortsRow> {
  List<YoutubeShort> _shorts = [];
  bool               _loading = true;
  bool               _hasError = false;

  // Largeur fixe de chaque card
  static const double _cardWidth  = 112.0;
  // Hauteur = ratio 9:16 + zone texte (titre 2 lignes + channel + espaceurs)
  // Marge généreuse pour tenir compte des métriques de police réelles.
  static const double _cardHeight = _cardWidth * (16 / 9) + 72;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final shorts = await YoutubeService.fetchShorts(
        widget.passion.name,
        widget.passion.id,
      );
      if (mounted) setState(() { _shorts = shorts; _loading = false; });
    } catch (e) {
      debugPrint('[ShortsRow] erreur: $e');
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  void _openPlayer(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ShortsPlayerScreen(
          shorts:       _shorts,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton();
    if (_hasError || _shorts.isEmpty) return const SizedBox.shrink();

    final primary = Theme.of(context).colorScheme.primary;
    // Affiche max 3 vraies cards + 1 card "Voir plus"
    final displayed = _shorts.take(3).toList();
    final showMore  = _shorts.length > 3;

    return SizedBox(
      height: _cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: displayed.length + (showMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          // Align(topLeft) casse la contrainte tight en hauteur du ListView
          // → le Column peut se dimensionner à son contenu réel.
          if (i < displayed.length) {
            return Align(
              alignment: Alignment.topLeft,
              child: _ShortCard(
                short:   displayed[i],
                primary: primary,
                onTap:   () => _openPlayer(i),
              ),
            );
          }
          // Card "Voir plus"
          return Align(
            alignment: Alignment.topLeft,
            child: _VoirPlusCard(
              primary:  primary,
              onTap:    () => _openPlayer(3),
            ),
          );
        },
      ),
    );
  }

  // ── Skeleton ──────────────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return SizedBox(
      height: _cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: _cardWidth,
            height: _cardHeight,
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
    );
  }
}

// ── Card d'un Short ──────────────────────────────────────────────────────────

class _ShortCard extends StatelessWidget {
  final YoutubeShort short;
  final Color        primary;
  final VoidCallback onTap;

  const _ShortCard({
    required this.short,
    required this.primary,
    required this.onTap,
  });

  static const double _cardWidth = 112.0;

  @override
  Widget build(BuildContext context) {
    final thumbHeight = _cardWidth * 16 / 9;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _cardWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Thumbnail 9:16 ─────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(children: [
                SizedBox(
                  width: _cardWidth,
                  height: thumbHeight,
                  child: CachedNetworkImage(
                    imageUrl: short.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                        color: Colors.black.withValues(alpha: 0.06)),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.black.withValues(alpha: 0.06),
                      child: const Icon(Icons.videocam_off_rounded,
                          color: Colors.white38, size: 24),
                    ),
                  ),
                ),

                // Dégradé bas
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bouton play centré
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                        )],
                      ),
                      child: Icon(Icons.play_arrow_rounded,
                          color: primary, size: 22),
                    ),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 6),

            // ── Titre ────────────────────────────────────────────────────────
            Text(
              short.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.firaSansCondensed(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
                height: 1.3,
              ),
            ),

            const SizedBox(height: 2),

            // ── Chaîne ───────────────────────────────────────────────────────
            Text(
              short.channelName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.firaSansCondensed(
                fontSize: 10,
                color: const Color(0xFF6B6B6B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card "Voir plus" ─────────────────────────────────────────────────────────

class _VoirPlusCard extends StatelessWidget {
  final Color        primary;
  final VoidCallback onTap;

  const _VoirPlusCard({required this.primary, required this.onTap});

  static const double _cardWidth = 112.0;

  @override
  Widget build(BuildContext context) {
    final thumbHeight = _cardWidth * 16 / 9;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _cardWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail zone ─────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: _cardWidth,
                height: thumbHeight,
                color: primary.withValues(alpha: 0.12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add,
                        color: primary, size: 26),
                    const SizedBox(height: 10),
                    Text(
                      'Voir plus',
                      style: GoogleFonts.firaSansCondensed(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Placeholder text pour aligner avec les autres cards
            Text(
              '',
              maxLines: 2,
              style: GoogleFonts.firaSansCondensed(
                fontSize: 11.5, height: 1.3),
            ),
            const SizedBox(height: 2),
            Text('', style: GoogleFonts.firaSansCondensed(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
