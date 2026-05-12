import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SUBTASK PAGE — une page du stepper plein écran d'un Jour.
// Le player extrait l'ID depuis subtask.videoUrl via YoutubePlayer.convertUrlToId.
// ─────────────────────────────────────────────────────────────────────────────

class SubtaskPage extends StatefulWidget {
  final PassionSubtask subtask;
  final int            indexInDay;     // 0-based dans le jour
  final int            totalInDay;     // nombre total de sous-tâches du jour
  final int            dayNumber;      // 1, 2, 3…
  final bool           alreadyDone;    // sous-tâche déjà cochée
  final VoidCallback   onSucceeded;
  final VoidCallback   onSkipped;

  const SubtaskPage({
    super.key,
    required this.subtask,
    required this.indexInDay,
    required this.totalInDay,
    required this.dayNumber,
    required this.alreadyDone,
    required this.onSucceeded,
    required this.onSkipped,
  });

  @override
  State<SubtaskPage> createState() => _SubtaskPageState();
}

class _SubtaskPageState extends State<SubtaskPage>
    with AutomaticKeepAliveClientMixin {
  YoutubePlayerController? _ytCtrl;
  bool _videoUnavailable = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final url = widget.subtask.videoUrl.trim();
    final id  = url.isEmpty ? null : YoutubePlayer.convertUrlToId(url);
    if (id == null || id.isEmpty) {
      _videoUnavailable = true;
    } else {
      _ytCtrl = YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          captionLanguage: 'fr',
          forceHD: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ytCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      color: AppColors.cream,
      child: Column(
        children: [
          // ── Lecteur vidéo (in-app, autoplay) ────────────────────────
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: _videoUnavailable || _ytCtrl == null
                  ? const _UnavailableThumb(label: '')
                  : YoutubePlayer(
                      controller: _ytCtrl!,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: primary,
                      progressColors: ProgressBarColors(
                        playedColor: primary,
                        handleColor: primary,
                      ),
                      onReady: () {},
                    ),
            ),
          ),

          // ── Contenu scrollable + CTA en bas ────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                22, 18, 22,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.subtask.title,
                    style: GoogleFonts.firaSansCondensed(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: AppColors.ink, height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.subtask.howTo.isNotEmpty)
                    Text(
                      widget.subtask.howTo,
                      style: GoogleFonts.firaSansCondensed(
                        fontSize: 14.5, height: 1.65, color: AppColors.ink,
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _UnavailableThumb extends StatelessWidget {
  final String label;
  const _UnavailableThumb({required this.label});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined,
                color: Colors.white.withValues(alpha: 0.4), size: 36),
            const SizedBox(height: 8),
            Text('Vidéo indisponible',
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7))),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.firaSansCondensed(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.45))),
            ],
          ],
        ),
      ),
    );
  }
}
