import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/core/theme/app_theme.dart';

/// Carte YouTube compacte affichée hors du chemin de la timeline.
/// Tap → ouvre la vidéo fullscreen in-app.
class TimelineVideoCard extends StatelessWidget {
  final AIVideo video;

  const TimelineVideoCard({
    super.key,
    required this.video,
  });

  void _openFullscreen(BuildContext context) {
    HapticFeedback.lightImpact();
    final id = YoutubePlayer.convertUrlToId(video.url);
    if (id == null || id.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _InAppVideoPage(videoId: id, title: video.title),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final primary      = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.85)!;

    return GestureDetector(
      onTap: () => _openFullscreen(context),
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.09),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Thumbnail avec play overlay ──────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video.effectiveThumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: primaryLight,
                        child: Icon(Icons.videocam_outlined, color: primary),
                      ),
                    ),
                    Container(color: Colors.black.withValues(alpha: 0.16)),
                    const Center(
                      child: Icon(Icons.play_circle_fill_rounded,
                          color: Colors.white, size: 34),
                    ),
                    // Badge +30 XP
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text('+30 XP',
                            style: GoogleFonts.firaSansCondensed(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Titre ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 9),
              child: Text(
                video.title,
                style: GoogleFonts.firaSansCondensed(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LECTEUR FULLSCREEN IN-APP
// ─────────────────────────────────────────────────────────────────────────────

class _InAppVideoPage extends StatefulWidget {
  final String videoId;
  final String title;

  const _InAppVideoPage({required this.videoId, required this.title});

  @override
  State<_InAppVideoPage> createState() => _InAppVideoPageState();
}

class _InAppVideoPageState extends State<_InAppVideoPage> {
  late final YoutubePlayerController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        forceHD: false,
      ),
    );
    // Masque la status bar pour un rendu immersif
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _ctrl,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Theme.of(context).colorScheme.primary,
      ),
      builder: (context, player) => Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            // ── Barre titre + close ──────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: Colors.white, height: 1.3,
                        ),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Lecteur ──────────────────────────────────────────────────
            player,
          ],
        ),
      ),
    );
  }
}
