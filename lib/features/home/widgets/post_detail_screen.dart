import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/features/home/widgets/community_models.dart';
import 'package:discover/features/home/widgets/avatar.dart';
import 'package:discover/features/home/widgets/comments_sheet.dart';
import 'package:discover/core/theme/app_theme.dart';

class PostDetailScreen extends StatefulWidget {
  final CommunityPost post;
  final Passion passion;
  final VoidCallback onLike;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.passion,
    required this.onLike,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {

  late CommunityPost _post;
  // Compteur local pour les mises à jour optimistes — initialisé depuis Firestore
  late int  _displayLikeCount;
  late bool _isLiked;

  @override
  void initState() {
    super.initState();
    _post             = widget.post;
    _displayLikeCount = widget.post.likeCount;   // valeur réelle Firestore
    _isLiked          = widget.post.isLiked;
  }

  void _handleLike() {
    widget.onLike();
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _displayLikeCount--;
      } else {
        _isLiked = true;
        _displayLikeCount++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding    = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(children: [
        // ── App bar ─────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 12),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 12),
            Avatar(
                initials: _post.authorInitials,
                colorHex: _post.authorColor,
                size: 36),
            const SizedBox(width: 10),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_post.authorName, style: GoogleFonts.firaSansCondensed(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  Text(_post.timeAgo, style: GoogleFonts.firaSansCondensed(
                      fontSize: 11, color: AppColors.inkSoft)),
                ])),
            Icon(Icons.more_horiz_rounded, color: AppColors.inkSoft),
          ]),
        ),

        // ── Image ───────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: CachedNetworkImage(
                  imageUrl: _post.imageUrl,
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
                        color: primary, size: 48),
                  ),
                ),
              ),

              // ── Actions ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(children: [
                  GestureDetector(
                    onTap: _handleLike,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _isLiked ? AppColors.errorLight : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isLiked
                              ? AppColors.errorPale
                              : Colors.black.withValues(alpha: 0.07),
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(_isLiked),
                            size: 18,
                            color: _isLiked ? AppColors.error : AppColors.inkSoft,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_displayLikeCount j\'aime',
                          style: GoogleFonts.firaSansCondensed(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isLiked ? AppColors.error : AppColors.inkSoft),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => CommentsSheet(
                          post: _post, passion: widget.passion),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.black.withValues(alpha: 0.07)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 17, color: AppColors.inkSoft),
                        const SizedBox(width: 6),
                        Text('${_post.commentCount} commentaires',
                            style: GoogleFonts.firaSansCondensed(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.inkSoft)),
                      ]),
                    ),
                  ),
                ]),
              ),

              // ── Caption ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Description',
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.black.withValues(alpha: 0.06)),
                      ),
                      child: Text(
                        _post.caption,
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 14, color: AppColors.ink, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
