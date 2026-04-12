import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:discover/features/home/widgets/community_models.dart';
import 'package:discover/features/home/widgets/avatar.dart';
import 'package:discover/core/theme/app_theme.dart';

class PostCard extends StatelessWidget {
  final CommunityPost post;
  final bool         isOwner;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  const PostCard({
    super.key,
    required this.post,
    required this.isOwner,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
  });

  void _showMoreMenu(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoreMenu(
        isOwner: isOwner,
        isReported: post.isReported,
        onEdit: () { Navigator.pop(context); onEdit(); },
        onDelete: () { Navigator.pop(context); onDelete(); },
        onReport: () { Navigator.pop(context); onReport(); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
          child: Row(children: [
            Avatar(
                initials: post.authorInitials,
                colorHex: post.authorColor,
                size: 36),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.authorName,
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  Text(post.timeAgo,
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 11, color: AppColors.inkSoft)),
                ])),
            // 3 petits points
            GestureDetector(
              onTap: () => _showMoreMenu(context),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.more_horiz_rounded,
                    color: AppColors.inkSoft, size: 20),
              ),
            ),
          ]),
        ),

        // ── Image (pas cliquable) ────────────────────────────────────────────
        ClipRRect(
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: CachedNetworkImage(
              imageUrl: post.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: primaryLight,
                child: Center(
                  child: CircularProgressIndicator(
                      color: primary, strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: primaryLight,
                child: Icon(Icons.image_outlined,
                    color: primary, size: 40),
              ),
            ),
          ),
        ),

        // ── Actions ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Row(children: [
            // Like
            GestureDetector(
              onTap: onLike,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: post.isLiked
                      ? AppColors.errorLight
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      post.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(post.isLiked),
                      size: 16,
                      color: post.isLiked
                          ? AppColors.error
                          : AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(width: 5),
                  // Affiche directement likeCount depuis Firestore — pas de +1
                  Text(
                    '${post.likeCount}',
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: post.isLiked
                            ? AppColors.error
                            : AppColors.inkSoft),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            // Commentaires
            GestureDetector(
              onTap: onComment,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 15, color: AppColors.inkSoft),
                  const SizedBox(width: 5),
                  Text('${post.commentCount}',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSoft)),
                ]),
              ),
            ),
            // Badge signalement
            if (post.reportCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 13, color: Color(0xFFE07B54)),
                    const SizedBox(width: 4),
                    Text('${post.reportCount}',
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE07B54))),
                  ]),
                ),
              ),
            const Spacer(),
            // Partager
            GestureDetector(
              onTap: onShare,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Icon(Icons.ios_share_rounded,
                    size: 15, color: AppColors.inkSoft),
              ),
            ),
          ]),
        ),

        // ── Description ─────────────────────────────────────────────────────
        if (post.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description',
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft,
                        letterSpacing: 0.4)),
                const SizedBox(height: 4),
                Text(post.caption,
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 13,
                        color: AppColors.ink,
                        height: 1.4)),
              ],
            ),
          )
        else
          const SizedBox(height: 8),
      ]),
    );
  }
}

// ── Menu 3 points ─────────────────────────────────────────────────────────────

class _MoreMenu extends StatelessWidget {
  final bool isOwner;
  final bool isReported;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  const _MoreMenu({
    required this.isOwner,
    required this.isReported,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: AppColors.cream,
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 20),

          if (isOwner) ...[
            _MenuItem(
              icon: Icons.edit_outlined,
              label: 'Modifier la publication',
              onTap: onEdit,
            ),
            const SizedBox(height: 10),
            _MenuItem(
              icon: Icons.delete_outline_rounded,
              label: 'Supprimer la publication',
              color: AppColors.error,
              onTap: onDelete,
            ),
          ] else ...[
            _MenuItem(
              icon: Icons.warning_amber_rounded,
              label: isReported ? 'Déjà signalé' : 'Signaler la publication',
              color: const Color(0xFFE07B54),
              onTap: isReported ? () => Navigator.pop(context) : onReport,
            ),
          ],
        ]),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color != null
              ? color!.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: color != null
                  ? color!.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.07)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.firaSansCondensed(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c)),
        ]),
      ),
    );
  }
}
