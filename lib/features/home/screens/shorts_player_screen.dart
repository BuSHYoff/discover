import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:discover/features/home/services/youtube_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHORTS PLAYER SCREEN — TikTok-style vertical PageView
// Utilise youtube_player_flutter (résout les erreurs 150/152 de l'IFrame).
// ─────────────────────────────────────────────────────────────────────────────

class ShortsPlayerScreen extends StatefulWidget {
  final List<YoutubeShort> shorts;
  final int                initialIndex;

  const ShortsPlayerScreen({
    super.key,
    required this.shorts,
    required this.initialIndex,
  });

  @override
  State<ShortsPlayerScreen> createState() => _ShortsPlayerScreenState();
}

class _ShortsPlayerScreenState extends State<ShortsPlayerScreen> {
  late final YoutubePlayerController _controller;
  late final PageController           _pageCtrl;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    // Verrouille en portrait, barre de statut blanche
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _controller = YoutubePlayerController(
      initialVideoId: widget.shorts[_currentIndex].id,
      flags: const YoutubePlayerFlags(
        autoPlay:               true,
        mute:                   false,
        enableCaption:          false,
        controlsVisibleAtStart: false,
        loop:                   true,
        isLive:                 false,
      ),
    );

    _pageCtrl = PageController(initialPage: _currentIndex);
  }

  void _loadVideo(int pageIndex) {
    final actual = pageIndex % widget.shorts.length;
    _controller.load(widget.shorts[actual].id);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageCtrl.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      // aspectRatio: 9/16 → YouTube sert les Shorts en portrait (pas 16:9)
      player: YoutubePlayer(
        controller:                  _controller,
        showVideoProgressIndicator:  false,
        aspectRatio:                 9 / 16,
        bottomActions: const [],
        topActions:    const [],
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [

              // ── PageView vertical TikTok ──────────────────────────────────
              PageView.builder(
                controller:      _pageCtrl,
                scrollDirection: Axis.vertical,
                // itemCount null = scroll infini ; on boucle via le modulo
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  _loadVideo(index);
                },
                itemBuilder: (_, index) {
                  final actual = index % widget.shorts.length;
                  return _ShortPage(
                    short:     widget.shorts[actual],
                    player:    player,
                    isCurrent: index == _currentIndex,
                  );
                },
              ),

              // ── Bouton fermer ─────────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),

            ],
          ),
        );
      },
    );
  }
}

// ── Page individuelle ────────────────────────────────────────────────────────

class _ShortPage extends StatelessWidget {
  final YoutubeShort short;
  final Widget       player;
  final bool         isCurrent;

  const _ShortPage({
    required this.short,
    required this.player,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return SizedBox(
      width:  size.width,
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [

          // ── Contenu principal ─────────────────────────────────────────────
          //
          // Player 9:16 → scalé à la hauteur de l'écran via OverflowBox
          // (scale by height, léger crop horizontal = style TikTok).
          // Exemple iPhone 14 (390×844) :
          //   player 9:16 → 474×844 ; ClipRect coupe 42px de chaque côté.
          //
          if (isCurrent)
            ClipRect(
              child: OverflowBox(
                minWidth:  size.height * (9 / 16),
                maxWidth:  size.height * (9 / 16),
                minHeight: size.height,
                maxHeight: size.height,
                alignment: Alignment.center,
                child: ColoredBox(
                  color: Colors.black,
                  child: player,
                ),
              ),
            )
          else
            CachedNetworkImage(
              imageUrl: short.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.black),
              errorWidget: (_, __, ___) => Container(color: Colors.black),
            ),

          // ── Dégradé bas ────────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),

          // ── Titre + chaîne ─────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 72, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      short.channelName,
                      style: GoogleFonts.firaSansCondensed(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      short.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.firaSansCondensed(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Chevrons swipe ─────────────────────────────────────────────────
          Positioned(
            right: 12, bottom: 80,
            child: Column(
              children: [
                Icon(Icons.keyboard_arrow_up_rounded,
                    color: Colors.white.withValues(alpha: 0.5), size: 28),
                const SizedBox(height: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withValues(alpha: 0.5), size: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
