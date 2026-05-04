import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:discover/features/home/services/youtube_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SHORTS PLAYER SCREEN — TikTok-style vertical PageView
// Chaque page lance automatiquement la vidéo au swipe.
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

    // Verrouille en portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls:        false,
        showFullscreenButton: false,
        mute:                false,
        loop:                false,
        strictRelatedVideos: true,
        playsInline:         true,
      ),
    );

    _pageCtrl = PageController(initialPage: _currentIndex);

    // Lance la première vidéo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVideo(_currentIndex);
    });
  }

  void _loadVideo(int index) {
    if (index < 0 || index >= widget.shorts.length) return;
    _controller.loadVideoById(videoId: widget.shorts[index].id);
  }

  @override
  void dispose() {
    _controller.close();
    _pageCtrl.dispose();
    // Rétablit les orientations
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── PageView vertical TikTok ────────────────────────────────────
          YoutubePlayerScaffold(
            controller: _controller,
            builder: (context, player) {
              return PageView.builder(
                controller:      _pageCtrl,
                scrollDirection: Axis.vertical,
                itemCount:       widget.shorts.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  _loadVideo(index);
                },
                itemBuilder: (_, index) {
                  final short = widget.shorts[index];
                  return _ShortPage(
                    short:      short,
                    player:     player,
                    isCurrent:  index == _currentIndex,
                  );
                },
              );
            },
          ),

          // ── Bouton fermer ────────────────────────────────────────────────
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

          // ── Indicateur de progression (index / total) ────────────────────
          Positioned(
            top: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 18),
                child: Text(
                  '${_currentIndex + 1} / ${widget.shorts.length}',
                  style: GoogleFonts.firaSansCondensed(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
          // ── Player (uniquement sur la page courante) ─────────────────────
          if (isCurrent)
            ColoredBox(
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: player,
                ),
              ),
            )
          else
            Container(color: Colors.black),

          // ── Dégradé bas pour le texte ─────────────────────────────────────
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

          // ── Titre + chaîne ───────────────────────────────────────────────
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

          // ── Chevrons swipe haut / bas ──────────────────────────────────
          Positioned(
            right: 12,
            bottom: 80,
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
