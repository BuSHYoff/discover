import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:discover/core/services/reddit_service.dart';
import 'package:discover/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REDDIT POST CARD
// ─────────────────────────────────────────────────────────────────────────────

class RedditPostCard extends StatelessWidget {
  final RedditPost post;
  const RedditPostCard({super.key, required this.post});

  Future<void> _open() async {
    final uri = Uri.parse(post.postUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(post.createdAt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours   < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays    < 30) return 'Il y a ${diff.inDays} j';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return 'Il y a $months mois';
    final years = (diff.inDays / 365).floor();
    return years == 1 ? 'Il y a 1 an' : 'Il y a $years ans';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;
    final hasSelftext = post.selftext.isNotEmpty;

    return GestureDetector(
      onTap: _open,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ───────────────────────────────────────────────────────
            if (hasImage)
              SizedBox(
                width: double.infinity,
                height: 180,
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          color: const Color(0xFFF0F0F0),
                          child: const Center(
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ),
                        ),
                ),
              ),

            // ── Contenu ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Reddit + subreddit + temps
                  Row(
                    children: [
                      _RedditBadge(subreddit: post.subreddit),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(),
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 11,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Titre
                  Text(
                    post.title,
                    style: GoogleFonts.firaSansCondensed(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.35,
                    ),
                  ),

                  // Selftext (description)
                  if (hasSelftext) ...[
                    const SizedBox(height: 6),
                    Text(
                      post.selftext,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.firaSansCondensed(
                        fontSize: 13,
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Footer : auteur + stats
                  Row(
                    children: [
                      // Avatar initiale
                      Container(
                        width: 22, height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4500),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            post.author.isNotEmpty
                                ? post.author[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.firaSansCondensed(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'u/${post.author}',
                          style: GoogleFonts.firaSansCondensed(
                            fontSize: 12,
                            color: AppColors.inkSoft,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Votes
                      const Icon(Icons.arrow_upward_rounded,
                          size: 13, color: Color(0xFFFF4500)),
                      const SizedBox(width: 2),
                      Text(
                        _formatCount(post.score),
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF4500),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Commentaires
                      const Icon(Icons.chat_bubble_outline_rounded,
                          size: 13, color: AppColors.inkSoft),
                      const SizedBox(width: 2),
                      Text(
                        _formatCount(post.numComments),
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ── Badge Reddit ──────────────────────────────────────────────────────────────

class _RedditBadge extends StatelessWidget {
  final String subreddit;
  const _RedditBadge({required this.subreddit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4500).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo Reddit (cercle orange + alien simplifié via icône)
          const Icon(Icons.reddit, size: 12, color: Color(0xFFFF4500)),
          const SizedBox(width: 4),
          Text(
            subreddit,
            style: GoogleFonts.firaSansCondensed(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFF4500),
            ),
          ),
        ],
      ),
    );
  }
}
