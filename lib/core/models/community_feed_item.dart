import 'package:discover/core/models/reddit_post.dart';
import 'package:discover/features/home/widgets/community_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CommunityFeedItem — union discriminée renvoyée par `GET /passions/:id/community`.
// Le backend merge déjà les posts app + Reddit et les trie par date desc.
//
// Sealed class Dart → match exhaustif côté UI via `switch`.
// ─────────────────────────────────────────────────────────────────────────────

sealed class CommunityFeedItem {
  const CommunityFeedItem();
  DateTime get createdAt;
}

class AppCommunityFeedItem extends CommunityFeedItem {
  final CommunityPost post;
  const AppCommunityFeedItem(this.post);

  @override
  DateTime get createdAt => post.createdAt;
}

class RedditCommunityFeedItem extends CommunityFeedItem {
  final RedditPost post;
  const RedditCommunityFeedItem(this.post);

  @override
  DateTime get createdAt => post.createdAt;
}

class CommunityFeed {
  final List<CommunityFeedItem> items;
  final String? nextCursor;

  const CommunityFeed({required this.items, this.nextCursor});
}
