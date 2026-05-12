// ─────────────────────────────────────────────────────────────────────────────
// Modèle RedditPost — miroir de backend/src/community/entities/reddit-post.entity.ts
// L'app ne parle plus jamais à Reddit en direct : tout passe par le backend.
// ─────────────────────────────────────────────────────────────────────────────

class RedditPost {
  final String   id;
  final String   title;
  final String   author;
  final String   selftext;
  final String?  imageUrl;
  final String   postUrl;
  final int      score;
  final int      numComments;
  final DateTime createdAt;
  final String   subreddit;

  const RedditPost({
    required this.id,
    required this.title,
    required this.author,
    required this.selftext,
    required this.imageUrl,
    required this.postUrl,
    required this.score,
    required this.numComments,
    required this.createdAt,
    required this.subreddit,
  });

  factory RedditPost.fromJson(Map<String, dynamic> j) => RedditPost(
    id:          j['id']          as String? ?? '',
    title:       j['title']       as String? ?? '',
    author:      j['author']      as String? ?? '',
    selftext:    j['selftext']    as String? ?? '',
    imageUrl:    j['imageUrl']    as String?,
    postUrl:     j['postUrl']     as String? ?? '',
    score:       (j['score']        as num?)?.toInt() ?? 0,
    numComments: (j['numComments']  as num?)?.toInt() ?? 0,
    createdAt:   DateTime.tryParse(j['createdAt'] as String? ?? '')
                     ?.toLocal() ?? DateTime.now(),
    subreddit:   j['subreddit']   as String? ?? '',
  );
}
