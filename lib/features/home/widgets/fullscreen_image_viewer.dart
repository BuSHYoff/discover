import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FULLSCREEN IMAGE VIEWER
// Fond blanc, barre du haut avec bouton fermer couleur thème.
// ─────────────────────────────────────────────────────────────────────────────

class FullscreenImageViewer extends StatelessWidget {
  final String  imageUrl;
  final String? heroTag;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    this.heroTag,
  });

  static void open(BuildContext context, String imageUrl, {String? heroTag}) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) =>
          FullscreenImageViewer(imageUrl: imageUrl, heroTag: heroTag),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final primary    = Theme.of(context).colorScheme.primary;
    final topPadding = MediaQuery.of(context).padding.top;
    final botPadding = MediaQuery.of(context).padding.bottom;

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (_, __, ___) => const Icon(
          Icons.broken_image_outlined, color: Colors.black26, size: 48),
    );

    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Barre du haut ──────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 10),
            child: Row(children: [
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ]),
          ),

          // ── Image centrée ──────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, botPadding + 16),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: image,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
