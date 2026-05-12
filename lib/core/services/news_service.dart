import 'package:discover/core/api/api_client.dart';
import 'package:discover/core/models/news_article.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NEWS SERVICE — thin wrapper sur `GET /passions/:passionId/news`.
//
// L'ancienne version appelait Google News RSS en direct depuis le téléphone
// et parsait du XML côté client. Tout est maintenant côté backend (cache
// 30 min mutualisé, parsing XML une seule fois pour tous les users).
// ─────────────────────────────────────────────────────────────────────────────

class NewsService {
  NewsService._();

  /// Cache mémoire local — clé = passionId. Le backend cache aussi 30 min,
  /// mais ce cache client évite de retaper le réseau pour un simple rebuild.
  static final Map<String, List<NewsArticle>> _cache = {};

  static Future<List<NewsArticle>> fetchNews(
    String passionId, {
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.containsKey(passionId)) {
      return _cache[passionId]!;
    }

    final raw = await ApiClient.get<List<dynamic>>(
      '/passions/$passionId/news',
      query: {'limit': limit},
      auth:  false,
    );

    final articles = raw
        .whereType<Map>()
        .map((e) => NewsArticle.fromJson(Map<String, dynamic>.from(e)))
        .where((a) => a.title.isNotEmpty && a.url.isNotEmpty)
        .toList();

    _cache[passionId] = articles;
    return articles;
  }

  static void invalidate(String passionId) => _cache.remove(passionId);
}
