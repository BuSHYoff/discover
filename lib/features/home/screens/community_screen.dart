import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:discover/core/models/community_feed_item.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/core/services/community_service.dart';
import 'package:discover/features/home/widgets/community_models.dart';
import 'package:discover/features/home/widgets/post_card.dart';
import 'package:discover/features/home/widgets/reddit_post_card.dart';
import 'package:discover/features/home/widgets/comments_sheet.dart';
import 'package:discover/features/home/screens/create_post_screen.dart';
import 'package:discover/features/home/widgets/edit_post_sheet.dart';
import 'package:discover/features/home/widgets/news_tab.dart';
import 'package:discover/core/theme/app_theme.dart';

class CommunityScreen extends StatefulWidget {
  final Passion passion;
  const CommunityScreen({super.key, required this.passion});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollCtrl = ScrollController();
  late TabController _tabCtrl;

  // Signal de rafraîchissement vers _PublicationsTab. On l'incrémente après
  // chaque mutation (publish, delete, edit) pour forcer un re-fetch.
  final ValueNotifier<int> _refreshTrigger = ValueNotifier(0);

  void _triggerRefresh() => _refreshTrigger.value++;

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;
  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    _refreshTrigger.dispose();
    super.dispose();
  }

  // ── Publish ───────────────────────────────────────────────────────────────

  void _openPublish() async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreatePostScreen(passion: widget.passion),
    ));
    // Au retour du CreatePostScreen, recharge le feed (le post a peut-être été créé).
    _triggerRefresh();
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

  void _editPost(CommunityPost post) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditPostSheet(post: post),
    );
    _triggerRefresh();
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
              CommunityService.reportPost(post.id, passionId: post.passionId);
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
              CommunityService.deletePost(post.id, passionId: post.passionId)
                  .then((_) => _triggerRefresh());
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
    final primary = Theme.of(context).colorScheme.primary;

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
              if (_isLoggedIn && _tabCtrl.index == 0)
                GestureDetector(
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
                ),
            ]),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: primary,
                  indicatorWeight: 2.5,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: primary,
                  unselectedLabelColor: AppColors.inkSoft,
                  dividerColor: Colors.black.withValues(alpha: 0.06),
                  labelStyle: GoogleFonts.firaSansCondensed(
                      fontSize: 14, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.firaSansCondensed(
                      fontSize: 14, fontWeight: FontWeight.w400),
                  tabs: const [
                    Tab(text: 'Publications'),
                    Tab(text: 'Actualités'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            // ── Onglet Publications ─────────────────────────────────────────
            _PublicationsTab(
              passion:        widget.passion,
              myUid:          _myUid,
              isLoggedIn:     _isLoggedIn,
              onPublish:      _openPublish,
              onLike:         _toggleLike,
              onComment:      _openComments,
              onShare:        _sharePost,
              onEdit:         _editPost,
              onDelete:       _deletePost,
              onReport:       _reportPost,
              refreshTrigger: _refreshTrigger,
            ),

            // ── Onglet Actualités ───────────────────────────────────────────
            NewsTab(
              passionId:   widget.passion.id,
              passionName: widget.passion.name,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Publications Tab ──────────────────────────────────────────────────────────

/// Trigger partagé pour forcer le refresh d'un onglet sans WebSocket.
/// Le parent incrémente la valeur après une mutation (publish, delete),
/// les enfants qui en dépendent re-fetchent.
class _PublicationsTab extends StatefulWidget {
  final Passion            passion;
  final String?            myUid;
  final bool               isLoggedIn;
  final VoidCallback       onPublish;
  final void Function(CommunityPost) onLike;
  final void Function(CommunityPost) onComment;
  final void Function(CommunityPost) onShare;
  final void Function(CommunityPost) onEdit;
  final void Function(CommunityPost) onDelete;
  final void Function(CommunityPost) onReport;
  final ValueListenable<int> refreshTrigger;

  const _PublicationsTab({
    required this.passion,
    required this.myUid,
    required this.isLoggedIn,
    required this.onPublish,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
    required this.refreshTrigger,
  });

  @override
  State<_PublicationsTab> createState() => _PublicationsTabState();
}

class _PublicationsTabState extends State<_PublicationsTab>
    with AutomaticKeepAliveClientMixin {

  // Feed mergé app + Reddit — déjà trié par date desc côté backend.
  // Feed mergé app + Reddit, déjà trié par date desc côté backend.
  late Future<CommunityFeed> _feedFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _feedFuture = CommunityService.fetchCommunityFeed(widget.passion.id);
    widget.refreshTrigger.addListener(_onRefreshTrigger);
  }

  void _onRefreshTrigger() => _refresh();

  @override
  void dispose() {
    widget.refreshTrigger.removeListener(_onRefreshTrigger);
    super.dispose();
  }

  /// Recharge le feed. Utilisé par pull-to-refresh + après mutations parent.
  Future<void> _refresh() async {
    final future = CommunityService.fetchCommunityFeed(widget.passion.id);
    setState(() { _feedFuture = future; });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final primary = Theme.of(context).colorScheme.primary;

    return FutureBuilder<CommunityFeed>(
            future: _feedFuture,
            builder: (context, snap) {
              if (snap.hasError) {
                debugPrint('[PublicationsTab] fetch error: ${snap.error}');
                return RefreshIndicator(
                  color: primary,
                  onRefresh: _refresh,
                  child: ListView(children: const [SizedBox(height: 80), _ErrorState()]),
                );
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: primary, strokeWidth: 2),
                );
              }

              final feed = snap.data?.items ?? const <CommunityFeedItem>[];

              if (feed.isEmpty) {
                return RefreshIndicator(
                  color: primary,
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      _EmptyFeed(
                        passionName: widget.passion.name,
                        onPublish:   widget.isLoggedIn ? widget.onPublish : null,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: primary,
                onRefresh: _refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 32),
                  itemCount: feed.length,
                  itemBuilder: (_, i) {
                    final item = feed[i];
                    return switch (item) {
                      AppCommunityFeedItem(:final post) => PostCard(
                          post:      post,
                          isOwner:   post.authorId == widget.myUid,
                          onLike:    () => widget.onLike(post),
                          onComment: () => widget.onComment(post),
                          onShare:   () => widget.onShare(post),
                          onEdit:    () => widget.onEdit(post),
                          onDelete:  () => widget.onDelete(post),
                          onReport:  () => widget.onReport(post),
                        ),
                      RedditCommunityFeedItem(:final post) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: RedditPostCard(post: post),
                        ),
                    };
                  },
                ),
              );
            },
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
