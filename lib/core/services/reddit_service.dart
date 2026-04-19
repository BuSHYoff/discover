import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// REDDIT SERVICE
// Utilise l'API JSON publique de Reddit (sans auth).
// Route : https://www.reddit.com/r/{subreddit}/top.json?limit=50&t=month
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
  final String   subreddit; // ex: "r/baduk"

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
}

class RedditService {
  static const _userAgent = 'flutter:discover:v0.1 (by /u/discover_app)';

  static Future<List<RedditPost>> fetchTopPosts(String subreddit) async {
    final uri = Uri.parse(
      'https://www.reddit.com/r/$subreddit/top.json?limit=50&t=month',
    );

    try {
      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[RedditService] HTTP ${response.statusCode}');
        return [];
      }

      final json     = jsonDecode(response.body) as Map<String, dynamic>;
      final children = (json['data']?['children'] as List?) ?? [];

      final posts = children.map((child) {
        final d = child['data'] as Map<String, dynamic>;
        return RedditPost(
          id:          d['id']   as String? ?? '',
          title:       d['title'] as String? ?? '',
          author:      d['author'] as String? ?? '',
          selftext:    d['selftext'] as String? ?? '',
          imageUrl:    _extractImage(d),
          postUrl:     'https://www.reddit.com${d['permalink'] ?? ''}',
          score:       (d['score'] as num?)?.toInt() ?? 0,
          numComments: (d['num_comments'] as num?)?.toInt() ?? 0,
          createdAt:   DateTime.fromMillisecondsSinceEpoch(
            ((d['created_utc'] as num?)?.toInt() ?? 0) * 1000,
          ),
          subreddit:   d['subreddit_name_prefixed'] as String? ?? 'r/$subreddit',
        );
      }).where((p) => p.id.isNotEmpty && p.title.isNotEmpty).toList();

      return posts;
    } catch (e) {
      debugPrint('[RedditService] error: $e');
      return [];
    }
  }

  /// Extrait l'image preview ~640px si disponible.
  static String? _extractImage(Map<String, dynamic> d) {
    final hint = d['post_hint'] as String?;
    if (hint != 'image' && hint != 'link') return null;

    final images = d['preview']?['images'] as List?;
    if (images == null || images.isEmpty) return null;

    final resolutions = images[0]['resolutions'] as List?;
    if (resolutions == null || resolutions.isEmpty) {
      // Fallback sur la source
      final src = images[0]['source']?['url'] as String?;
      return src != null ? _decodeUrl(src) : null;
    }

    // Prend la résolution ~640px (index 4) ou la plus grande dispo
    final target = resolutions.length > 4 ? resolutions[4] : resolutions.last;
    final url    = target['url'] as String?;
    return url != null ? _decodeUrl(url) : null;
  }

  /// Reddit encode les & en &amp; dans les URLs JSON.
  static String _decodeUrl(String url) => url.replaceAll('&amp;', '&');
}
