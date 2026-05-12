import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/features/home/widgets/glisse_hint.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHORTS PLAYER SCREEN — TikTok-style vertical PageView
// Utilise youtube_player_flutter (résout les erreurs 150/152 de l'IFrame).
// ─────────────────────────────────────────────────────────────────────────────

class ShortsPlayerScreen extends StatefulWidget {
  final List<AIVideo> shorts;
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
      initialVideoId:
          YoutubePlayer.convertUrlToId(widget.shorts[_currentIndex].url) ?? '',
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
    final id = YoutubePlayer.convertUrlToId(widget.shorts[actual].url);
    if (id != null && id.isNotEmpty) _controller.load(id);
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

              // ── Bouton fermer (fond blanc, croix dans la couleur du thème) ─
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 26,
                      ),
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
  final AIVideo short;
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
              imageUrl: short.effectiveThumbnail,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.black),
              errorWidget: (_, __, ___) => Container(color: Colors.black),
            ),

          // ── Dégradé bas (élargi pour englober le hint en bas) ──────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.90),
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bloc texte aligné gauche
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            short.channel,
                            style: GoogleFonts.firaSansCondensed(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            short.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.firaSansCondensed(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.95),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // "Glisse pour découvrir" tout en bas
                    const GlisseHint(
                      textSize: 12,
                      iconSize: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
