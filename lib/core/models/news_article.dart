// ─────────────────────────────────────────────────────────────────────────────
// Modèle NewsArticle — miroir de backend/src/news/entities/news-article.entity.ts
// Source actuelle (transparente côté client) : Google News RSS.
// ─────────────────────────────────────────────────────────────────────────────

class NewsArticle {
  final String   title;
  final String   source;
  final String   sourceUrl;
  final String   url;
  final DateTime publishedAt;

  const NewsArticle({
    required this.title,
    required this.source,
    required this.sourceUrl,
    required this.url,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> j) => NewsArticle(
    title:       j['title']     as String? ?? '',
    source:      j['source']    as String? ?? '',
    sourceUrl:   j['sourceUrl'] as String? ?? '',
    url:         j['url']       as String? ?? '',
    publishedAt: DateTime.tryParse(j['publishedAt'] as String? ?? '')
                     ?.toLocal() ?? DateTime.now(),
  );
}
