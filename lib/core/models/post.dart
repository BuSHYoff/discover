// ─────────────────────────────────────────────────────────────────────────────
// Modèles Post + Comment — alignés sur backend/src/posts/entities/*.entity.ts
// ─────────────────────────────────────────────────────────────────────────────

/// Post de communauté. Miroir de l'entité backend.
///
/// `authorId` est l'UID Firebase ; les écrans qui veulent afficher un nom
/// résolvent l'auteur séparément (cf. `CommunityPost` dans community_models.dart
/// qui enrichit ce modèle avec les infos d'affichage).
class Post {
  final String id;
  final String passionId;
  final String authorId;
  final String imageUrl;
  final String title;
  final String caption;
  final int    likeCount;
  final int    commentCount;
  final List<String> likedBy;
  final List<String> reportedBy;
  final int    reportCount;
  final DateTime? createdAt;

  const Post({
    required this.id,
    required this.passionId,
    required this.authorId,
    required this.imageUrl,
    required this.title,
    required this.caption,
    required this.likeCount,
    required this.commentCount,
    this.likedBy     = const [],
    this.reportedBy  = const [],
    this.reportCount = 0,
    this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> j) => Post(
    id:           j['id']           as String,
    passionId:    j['passionId']    as String? ?? '',
    authorId:     j['authorId']     as String? ?? '',
    imageUrl:     j['imageUrl']     as String? ?? '',
    title:        j['title']        as String? ?? '',
    caption:      j['caption']      as String? ?? '',
    likeCount:    (j['likeCount']    as num?)?.toInt() ?? 0,
    commentCount: (j['commentCount'] as num?)?.toInt() ?? 0,
    likedBy:      List<String>.from(j['likedBy']    as List? ?? const []),
    reportedBy:   List<String>.from(j['reportedBy'] as List? ?? const []),
    reportCount:  (j['reportCount']  as num?)?.toInt() ?? 0,
    createdAt:    _parseDate(j['createdAt']),
  );
}

class PostComment {
  final String id;
  final String authorId;
  final String text;
  final DateTime? createdAt;

  const PostComment({
    required this.id,
    required this.authorId,
    required this.text,
    this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> j) => PostComment(
    id:        j['id']       as String,
    authorId:  j['authorId'] as String? ?? '',
    text:      j['text']     as String? ?? '',
    createdAt: _parseDate(j['createdAt']),
  );
}

/// Page de pagination cursor-based renvoyée par `GET /passions/:id/posts`.
class PaginatedPosts {
  final List<Post> items;
  final String?    nextCursor;

  const PaginatedPosts({required this.items, this.nextCursor});

  factory PaginatedPosts.fromJson(Map<String, dynamic> j) => PaginatedPosts(
    items: (j['items'] as List? ?? const [])
        .map((e) => Post.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    nextCursor: j['nextCursor'] as String?,
  );
}

DateTime? _parseDate(dynamic raw) {
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
