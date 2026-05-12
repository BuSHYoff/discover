// ─────────────────────────────────────────────────────────────────────────────
// Modèles UI pour les posts + commentaires.
// Enrichissent les modèles bruts du backend (Post, PostComment) avec les
// infos d'affichage résolues depuis l'API users (authorName, color, etc.).
// ─────────────────────────────────────────────────────────────────────────────

class CommunityPost {
  final String id;
  final String passionId;
  final String authorId;
  // Résolus depuis users/{authorId} via CommunityService
  final String authorName;
  final String authorInitials;
  final String authorColor;
  final String imageUrl;
  final String title;
  final String caption;
  final int    likeCount;
  final int    commentCount;
  final List<String> likedBy;
  final DateTime createdAt;
  bool isLiked;
  final int reportCount;
  final List<String> reportedBy;
  bool isReported;

  CommunityPost({
    required this.id,
    required this.passionId,
    required this.authorId,
    required this.authorName,
    required this.authorInitials,
    required this.authorColor,
    required this.imageUrl,
    required this.title,
    required this.caption,
    required this.likeCount,
    required this.commentCount,
    required this.likedBy,
    required this.createdAt,
    this.isLiked = false,
    this.reportCount = 0,
    this.reportedBy = const [],
    this.isReported = false,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1)  return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24)   return 'il y a ${diff.inHours}h';
    if (diff.inDays < 7)     return 'il y a ${diff.inDays}j';
    return 'il y a ${(diff.inDays / 7).floor()} sem.';
  }
}

class CommunityComment {
  final String id;
  final String authorId;
  final String authorName;
  final String authorInitials;
  final String authorColor;
  final String text;
  final DateTime createdAt;

  const CommunityComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorInitials,
    required this.authorColor,
    required this.text,
    required this.createdAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1)  return 'à l\'instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24)   return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}
