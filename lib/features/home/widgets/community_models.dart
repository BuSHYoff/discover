import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String passionId;
  final String authorId;
  // Résolus depuis users/{authorId} — pas stockés dans le post
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

  /// Construit un CommunityPost à partir d'un doc Firestore + infos auteur
  /// résolues séparément (depuis la collection users).
  factory CommunityPost.fromDoc({
    required DocumentSnapshot<Map<String, dynamic>> snap,
    required String currentUid,
    required String authorName,
    required String authorInitials,
    required String authorColor,
  }) {
    final d          = snap.data()!;
    final likedBy    = List<String>.from(d['likedBy'] ?? []);
    final reportedBy = List<String>.from(d['reportedBy'] ?? []);
    return CommunityPost(
      id:             snap.id,
      passionId:      d['passionId']     ?? '',
      authorId:       d['authorId']      ?? '',
      authorName:     authorName,
      authorInitials: authorInitials,
      authorColor:    authorColor,
      imageUrl:       d['imageUrl']      ?? '',
      title:          d['title']         ?? '',
      caption:        d['caption']       ?? '',
      likeCount:      (d['likeCount']    ?? 0) as int,
      commentCount:   (d['commentCount'] ?? 0) as int,
      likedBy:        likedBy,
      createdAt:      (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isLiked:        likedBy.contains(currentUid),
      reportCount:    (d['reportCount']  ?? 0) as int,
      reportedBy:     reportedBy,
      isReported:     reportedBy.contains(currentUid),
    );
  }

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
  // Résolus depuis users/{authorId}
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

  factory CommunityComment.fromDoc({
    required DocumentSnapshot<Map<String, dynamic>> snap,
    required String authorName,
    required String authorInitials,
    required String authorColor,
  }) {
    final d = snap.data()!;
    return CommunityComment(
      id:             snap.id,
      authorId:       d['authorId'] ?? '',
      authorName:     authorName,
      authorInitials: authorInitials,
      authorColor:    authorColor,
      text:           d['text']     ?? '',
      createdAt:      (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1)  return 'à l\'instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24)   return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}
