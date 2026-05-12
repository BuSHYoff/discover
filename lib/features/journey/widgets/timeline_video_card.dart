import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/core/theme/app_theme.dart';

/// Carte YouTube compacte affichée hors du chemin de la timeline.
/// Tap → ouvre la vidéo fullscreen in-app. Quand [locked], la carte est
/// grisée + cadenas overlay, et le tap est dead (juste haptic).
class TimelineVideoCard extends StatelessWidget {
  final AIVideo        video;
  final bool           locked;
  final VoidCallback?  onLockedTap;

  const TimelineVideoCard({
    super.key,
    required this.video,
    this.locked = false,
    this.onLockedTap,
  });

  void _openFullscreen(BuildContext context) {
    HapticFeedback.lightImpact();
    final id = YoutubePlayer.convertUrlToId(video.url);
    if (id == null || id.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _InAppVideoPage(videoId: id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final primary      = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.85)!;

    final card = Container(
      width: 148,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: locked ? 0.04 : 0.09),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Thumbnail avec play overlay (ou cadenas si verrouillé) ────
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
                  Container(
                    color: Colors.black.withValues(
                        alpha: locked ? 0.55 : 0.16),
                  ),
                  Center(
                    child: Icon(
                      locked
                          ? Icons.lock_rounded
                          : Icons.play_circle_fill_rounded,
                      color: Colors.white, size: locked ? 26 : 34,
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
                color: locked ? AppColors.inkFaint : AppColors.ink,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    // Tap quand locked → haptic + callback (parent ouvre une info sheet)
    return GestureDetector(
      onTap: locked
          ? () {
              HapticFeedback.heavyImpact();
              onLockedTap?.call();
            }
          : () => _openFullscreen(context),
      child: Opacity(
        opacity: locked ? 0.55 : 1.0,
        child: card,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LECTEUR FULLSCREEN IN-APP
// ─────────────────────────────────────────────────────────────────────────────

class _InAppVideoPage extends StatefulWidget {
  final String videoId;

  const _InAppVideoPage({required this.videoId});

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
    final primary = Theme.of(context).colorScheme.primary;
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _ctrl,
        showVideoProgressIndicator: true,
        progressIndicatorColor: primary,
      ),
      builder: (context, player) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Vidéo centrée verticalement ──────────────────────────────
            Center(child: player),

            // ── Bouton close en haut à gauche (même style que les shorts) ─
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                      color: primary,
                      size: 26,
                    ),
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
