import 'package:discover/features/home/widgets/community_models.dart';
import 'package:discover/core/services/reddit_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FEED ITEM — modèle unifié pour les posts app + Reddit
// ─────────────────────────────────────────────────────────────────────────────

sealed class FeedItem {
  DateTime get createdAt;
}

class AppFeedItem extends FeedItem {
  final CommunityPost post;
  AppFeedItem(this.post);

  @override
  DateTime get createdAt => post.createdAt;
}

class RedditFeedItem extends FeedItem {
  final RedditPost post;
  RedditFeedItem(this.post);

  @override
  DateTime get createdAt => post.createdAt;
}
