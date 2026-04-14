import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/core/services/community_service.dart';
import 'package:discover/features/home/widgets/community_models.dart';
import 'package:discover/features/home/widgets/post_card.dart';
import 'package:discover/features/home/widgets/comments_sheet.dart';
import 'package:discover/features/home/widgets/share_creation_sheet.dart';
import 'package:discover/features/home/widgets/edit_post_sheet.dart';
import 'package:discover/core/theme/app_theme.dart';

class CommunityScreen extends StatefulWidget {
  final Passion passion;
  const CommunityScreen({super.key, required this.passion});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;
  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Publish ───────────────────────────────────────────────────────────────

  void _openPublish() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ShareCreationSheet(passion: widget.passion),
    );
  }

  // ── Like ──────────────────────────────────────────────────────────────────

  void _toggleLike(CommunityPost post) {
    HapticFeedback.selectionClick();
    final isNowLiked = !post.isLiked;
    // Optimistic UI
    setState(() => post.isLiked = isNowLiked);
    // Sync Firestore via transaction (impossible d'aller en négatif)
    CommunityService.toggleLike(post.id, isNowLiked, post.passionId);
  }

  // ── Comments ──────────────────────────────────────────────────────────────

  void _openComments(CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(post: post, passion: widget.passion),
    );
  }

  // ── Share ─────────────────────────────────────────────────────────────────

  void _sharePost(CommunityPost post) {
    final text = StringBuffer();
    text.write('Découvre cette publication sur ${widget.passion.name} dans Discover !');
    if (post.caption.isNotEmpty) {
      text.write('\n\n${post.caption}');
    }
    text.write('\n\n${post.imageUrl}');
    SharePlus.instance.share(ShareParams(text: text.toString()));
  }

  // ── Edit ──────────────────────────────────────────────────────────────────

  void _editPost(CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditPostSheet(post: post),
    );
  }

  // ── Report ────────────────────────────────────────────────────────────────

  void _reportPost(CommunityPost post) {
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

  // ── Delete ────────────────────────────────────────────────────────────────

  void _deletePost(CommunityPost post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Supprimer la publication ?',
            style: GoogleFonts.firaSansCondensed(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
        content: Text(
            'Cette action est irréversible.',
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
              HapticFeedback.lightImpact();
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: NestedScrollView(
        controller: _scrollCtrl,
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: AppColors.cream,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            automaticallyImplyLeading: false,
            toolbarHeight: 72,
            title: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.black.withValues(alpha: 0.07)),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8)],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Communauté',
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    Text(widget.passion.name,
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 12, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              if (_isLoggedIn)
                Builder(builder: (context) {
                  final primary = Theme.of(context).colorScheme.primary;
                  return GestureDetector(
                    onTap: _openPublish,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: primary, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                            color: primary.withValues(alpha: 0.25),
                            blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 24),
                    ),
                  );
                }),
            ]),
          ),
        ],
        body: StreamBuilder<List<CommunityPost>>(
          stream: CommunityService.streamPosts(widget.passion.id),
          builder: (context, snap) {
            if (snap.hasError) {
              debugPrint('[CommunityScreen] stream error: ${snap.error}');
              return const _ErrorState();
            }

            if (snap.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary, strokeWidth: 2),
              );
            }

            final posts = snap.data ?? [];

            if (posts.isEmpty) {
              return _EmptyFeed(
                passionName: widget.passion.name,
                onPublish: _isLoggedIn ? _openPublish : null,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              itemCount: posts.length,
              itemBuilder: (_, i) {
                final post = posts[i];
                return PostCard(
                  post:      post,
                  isOwner:   post.authorId == _myUid,
                  onLike:    () => _toggleLike(post),
                  onComment: () => _openComments(post),
                  onShare:   () => _sharePost(post),
                  onEdit:    () => _editPost(post),
                  onDelete:  () => _deletePost(post),
                  onReport:  () => _reportPost(post),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyFeed extends StatelessWidget {
  final String passionName;
  /// null = invité (pas de bouton de publication)
  final VoidCallback? onPublish;

  const _EmptyFeed({required this.passionName, required this.onPublish});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
    final isGuest = onPublish == null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: primary.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.photo_library_outlined, color: primary, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucune publication pour le moment',
              textAlign: TextAlign.center,
              style: GoogleFonts.firaSansCondensed(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            Text(
              isGuest
                  ? 'Crée un compte pour partager ta progression sur $passionName avec la communauté !'
                  : 'Sois le premier à partager ta progression sur $passionName avec la communauté !',
              textAlign: TextAlign.center,
              style: GoogleFonts.firaSansCondensed(
                  fontSize: 14, color: AppColors.inkSoft, height: 1.5),
            ),
            if (!isGuest) ...[
              const SizedBox(height: 28),
              GestureDetector(
                onTap: onPublish,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                        color: primary.withValues(alpha: 0.25),
                        blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('Partager une création',
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded,
                  color: AppColors.error.withValues(alpha: 0.6), size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: GoogleFonts.firaSansCondensed(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              'Impossible de charger les publications.\nVérifie ta connexion et réessaie.',
              textAlign: TextAlign.center,
              style: GoogleFonts.firaSansCondensed(
                  fontSize: 13, color: AppColors.inkSoft, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
