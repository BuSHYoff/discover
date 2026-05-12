import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:discover/core/api/api_client.dart';
import 'package:discover/core/models/community_feed_item.dart';
import 'package:discover/core/models/post.dart';
import 'package:discover/core/models/reddit_post.dart';
import 'package:discover/features/home/widgets/community_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COMMUNITY SERVICE
// Toutes les opérations posts/likes/comments passent par l'API NestJS.
// L'upload d'image utilise la route signée `POST /passions/:id/posts/upload`
// qui pousse vers Cloudinary côté backend.
//
// Important : l'API ne renvoie pas les infos d'auteur (username/color) dans
// les posts pour rester léger. On résout ces infos en lazy via l'API
// `GET /users/:uid` pour les écrans qui en ont besoin, avec cache mémoire.
// ─────────────────────────────────────────────────────────────────────────────

class CommunityService {
  CommunityService._();

  // ── Cache d'auteurs (uid → données users) ─────────────────────────────────
  static final Map<String, Map<String, dynamic>> _userCache = {};

  static void clearUserCache() => _userCache.clear();

  static Future<Map<String, dynamic>> _getUser(String uid) async {
    if (uid.isEmpty) return const {};
    final cached = _userCache[uid];
    if (cached != null && (cached['username'] as String?)?.isNotEmpty == true) {
      return cached;
    }
    try {
      final data = await ApiClient.get<Map<String, dynamic>>('/users/$uid');
      if ((data['username'] as String?)?.isNotEmpty == true) {
        _userCache[uid] = data;
      }
      return data;
    } catch (_) {
      return const {};
    }
  }

  static Future<void> _prefetchUsers(Iterable<String> uids) async {
    final toLoad =
        uids.where((id) => id.isNotEmpty && !_userCache.containsKey(id)).toSet();
    if (toLoad.isEmpty) return;
    await Future.wait(toLoad.map(_getUser));
  }

  // ── Helpers affichage ────────────────────────────────────────────────────

  static String _name(Map<String, dynamic> u) =>
      (u['username'] as String?)?.trim().isNotEmpty == true
          ? u['username'] as String
          : 'Utilisateur';

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  static String _color(Map<String, dynamic> u, String uid) {
    if (u['profileColor'] != null) return u['profileColor'] as String;
    const colors = [
      '#4CAF8A', '#5B8ED6', '#E07B54',
      '#9B6DB5', '#D4896A', '#2D5A3D',
    ];
    final idx = uid.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[idx];
  }

  static String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  // ── Posts ────────────────────────────────────────────────────────────────

  /// Fetch tous les posts d'une passion (page actuelle uniquement).
  /// Pour la pagination cursor, on rechargerait avec `?cursor=…`.
  ///
  /// ⚠️  Cette méthode renvoie UNIQUEMENT les posts de l'app (pas Reddit).
  /// Pour le feed mergé app + Reddit, utiliser [fetchCommunityFeed].
  static Future<List<CommunityPost>> fetchPosts(String passionId, {int limit = 50}) async {
    final json = await ApiClient.get<Map<String, dynamic>>(
      '/passions/$passionId/posts',
      query: {'limit': limit},
      auth:  false,
    );
    final page = PaginatedPosts.fromJson(json);
    return _hydratePosts(page.items);
  }

  /// Feed community unifié — posts app + Reddit déjà mergés et triés
  /// par date desc côté backend. Un seul appel HTTP.
  ///
  /// [includeReddit] : si false, n'inclut que les posts de l'app.
  static Future<CommunityFeed> fetchCommunityFeed(
    String passionId, {
    int limit = 50,
    bool includeReddit = true,
  }) async {
    final json = await ApiClient.get<Map<String, dynamic>>(
      '/passions/$passionId/community',
      query: {
        'limit':         limit,
        'includeReddit': includeReddit,
      },
      auth: false,
    );

    final rawItems = (json['items'] as List? ?? const []).whereType<Map>();
    final rawAppPosts = <Post>[];
    final mapped     = <_PendingItem>[];

    // Première passe : on extrait les Post bruts pour les hydrater en batch
    // (résolution des auteurs via /users/:uid en parallèle, cf. _hydratePosts).
    for (final m in rawItems) {
      final type = m['type'] as String? ?? '';
      final post = Map<String, dynamic>.from(m['post'] as Map? ?? const {});
      if (type == 'app') {
        final p = Post.fromJson(post);
        rawAppPosts.add(p);
        mapped.add(_PendingItem.app(p));
      } else if (type == 'reddit') {
        mapped.add(_PendingItem.reddit(RedditPost.fromJson(post)));
      }
    }

    // Hydrate les posts app (auteur, color, etc.). Conserve l'ordre via lookup id.
    final hydratedApp = await _hydratePosts(rawAppPosts);
    final byId        = { for (final p in hydratedApp) p.id: p };

    final items = <CommunityFeedItem>[];
    for (final p in mapped) {
      if (p.appPost != null) {
        final hyd = byId[p.appPost!.id];
        if (hyd != null) items.add(AppCommunityFeedItem(hyd));
      } else if (p.redditPost != null) {
        items.add(RedditCommunityFeedItem(p.redditPost!));
      }
    }

    return CommunityFeed(
      items:      items,
      nextCursor: json['nextCursor'] as String?,
    );
  }

  /// Posts de l'utilisateur connecté.
  static Future<List<CommunityPost>> fetchMyPosts() async {
    final raw = await ApiClient.get<List<dynamic>>('/users/me/posts');
    final posts = raw
        .whereType<Map>()
        .map((e) => Post.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return _hydratePosts(posts);
  }

  /// Crée un post — upload multipart vers Cloudinary via le backend.
  static Future<void> addPost({
    required String passionId,
    required File   imageFile,
    required String title,
    required String caption,
  }) async {
    await ApiClient.uploadPostImage(
      passionId: passionId,
      imageFile: imageFile,
      title:     title,
      caption:   caption,
    );
  }

  /// Toggle like — idempotent côté backend.
  static Future<void> toggleLike(String postId, bool isNowLiked, String passionId) async {
    await ApiClient.post<dynamic>(
      '/passions/$passionId/posts/$postId/like',
      body: {'liked': isNowLiked},
    );
  }

  /// Supprime un post (auteur ou admin).
  static Future<void> deletePost(String postId, {required String passionId}) async {
    await ApiClient.delete<dynamic>('/passions/$passionId/posts/$postId');
  }

  /// Édite caption + image éventuelle.
  static Future<void> updatePost({
    required String postId,
    required String passionId,
    required String caption,
    File? newImageFile,
  }) async {
    // Pour le moment, le backend accepte uniquement PATCH JSON (sans image).
    // Si l'admin change l'image, on re-upload via la route /upload qui crée
    // un nouveau post — fonctionnellement, on patch le caption seul ici.
    await ApiClient.patch<dynamic>(
      '/passions/$passionId/posts/$postId',
      body: {'caption': caption},
    );
    // newImageFile intentionnellement ignoré : pas d'endpoint backend pour
    // remplacer l'image d'un post existant. À ajouter si besoin.
    if (newImageFile != null) {
      // No-op explicite — laisser un log dev pourrait être utile.
    }
  }

  /// Signale un post.
  static Future<void> reportPost(String postId, {required String passionId}) async {
    await ApiClient.post<dynamic>('/passions/$passionId/posts/$postId/report');
  }

  // ── Commentaires ─────────────────────────────────────────────────────────

  static Future<List<CommunityComment>> fetchComments(
    String postId, {
    required String passionId,
  }) async {
    final raw = await ApiClient.get<List<dynamic>>(
      '/passions/$passionId/posts/$postId/comments',
      auth: false,
    );
    final comments = raw
        .whereType<Map>()
        .map((e) => PostComment.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    await _prefetchUsers(comments.map((c) => c.authorId));

    final out = <CommunityComment>[];
    for (final c in comments) {
      final u    = await _getUser(c.authorId);
      final name = _name(u);
      out.add(CommunityComment(
        id:             c.id,
        authorId:       c.authorId,
        authorName:     name,
        authorInitials: _initials(name),
        authorColor:    _color(u, c.authorId),
        text:           c.text,
        createdAt:      c.createdAt ?? DateTime.now(),
      ));
    }
    return out;
  }

  static Future<void> addComment(
    String postId,
    String text, {
    required String passionId,
  }) async {
    if (text.trim().isEmpty) return;
    await ApiClient.post<dynamic>(
      '/passions/$passionId/posts/$postId/comments',
      body: {'text': text.trim()},
    );
  }

  // ── Helpers internes ─────────────────────────────────────────────────────

  static Future<List<CommunityPost>> _hydratePosts(List<Post> posts) async {
    final uid = _myUid ?? '';
    await _prefetchUsers(posts.map((p) => p.authorId));

    final out = <CommunityPost>[];
    for (final p in posts) {
      final u    = await _getUser(p.authorId);
      final name = _name(u);
      out.add(CommunityPost(
        id:             p.id,
        passionId:      p.passionId,
        authorId:       p.authorId,
        authorName:     name,
        authorInitials: _initials(name),
        authorColor:    _color(u, p.authorId),
        imageUrl:       p.imageUrl,
        title:          p.title,
        caption:        p.caption,
        likeCount:      p.likeCount,
        commentCount:   p.commentCount,
        likedBy:        p.likedBy,
        createdAt:      p.createdAt ?? DateTime.now(),
        isLiked:        p.likedBy.contains(uid),
        reportCount:    p.reportCount,
        reportedBy:     p.reportedBy,
        isReported:     p.reportedBy.contains(uid),
      ));
    }
    return out;
  }
}

/// Helper interne — sert à conserver l'ordre du feed pendant qu'on hydrate
/// les posts app en parallèle (résolution auteurs). Une seule des 2 props est
/// non-null à la fois.
class _PendingItem {
  final Post?       appPost;
  final RedditPost? redditPost;
  _PendingItem._(this.appPost, this.redditPost);
  factory _PendingItem.app(Post p)       => _PendingItem._(p, null);
  factory _PendingItem.reddit(RedditPost p) => _PendingItem._(null, p);
}
