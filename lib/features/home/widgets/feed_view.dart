import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:discover/features/home/widgets/community_models.dart';
import 'package:discover/features/home/widgets/post_card.dart';
import 'package:discover/features/home/widgets/edit_post_sheet.dart';
import 'package:discover/core/services/community_service.dart';
import 'package:discover/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class FeedView extends StatefulWidget {
  final List<CommunityPost> posts;
  final String passionName;

  const FeedView({
    super.key,
    required this.posts,
    required this.passionName,
  });

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  void _toggleLike(CommunityPost post) {
    final isNowLiked = !post.isLiked;
    setState(() => post.isLiked = isNowLiked);
    CommunityService.toggleLike(post.id, isNowLiked, post.passionId);
  }

  void _openComments(CommunityPost post) {
    // Géré par le parent si besoin — ici no-op par défaut
  }

  void _sharePost(CommunityPost post) {
    final text = StringBuffer();
    text.write('Découvre cette publication sur ${widget.passionName} dans Discover !');
    if (post.caption.isNotEmpty) text.write('\n\n${post.caption}');
    text.write('\n\n${post.imageUrl}');
    SharePlus.instance.share(ShareParams(text: text.toString()));
  }

  void _editPost(BuildContext context, CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditPostSheet(post: post),
    );
  }

  void _reportPost(BuildContext context, CommunityPost post) {
    if (post.isReported) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Signaler cette publication ?',
            style: GoogleFonts.firaSansCondensed(
                fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        content: Text('Cette publication sera examinée par notre équipe.',
            style: GoogleFonts.firaSansCondensed(
                fontSize: 14, color: AppColors.inkSoft)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 14, color: AppColors.inkSoft)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              CommunityService.reportPost(post.id);
              setState(() => post.isReported = true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Publication signalée. Merci !',
                      style: GoogleFonts.firaSansCondensed(fontSize: 13)),
                  backgroundColor: const Color(0xFFE07B54),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Text('Signaler',
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE07B54))),
          ),
        ],
      ),
    );
  }

  void _deletePost(BuildContext context, CommunityPost post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Supprimer la publication ?',
            style: GoogleFonts.firaSansCondensed(
                fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        content: Text('Cette action est irréversible.',
            style: GoogleFonts.firaSansCondensed(
                fontSize: 14, color: AppColors.inkSoft)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 14, color: AppColors.inkSoft)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              CommunityService.deletePost(post.id);
            },
            child: Text('Supprimer',
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      itemCount: widget.posts.length,
      itemBuilder: (_, i) {
        final post = widget.posts[i];
        return PostCard(
          post:      post,
          isOwner:   post.authorId == _myUid,
          onLike:    () => _toggleLike(post),
          onComment: () => _openComments(post),
          onShare:   () => _sharePost(post),
          onEdit:    () => _editPost(context, post),
          onDelete:  () => _deletePost(context, post),
          onReport:  () => _reportPost(context, post),
        );
      },
    );
  }
}
