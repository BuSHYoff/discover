import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NEWS SERVICE — Google News RSS
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
}

class NewsService {
  static const _baseUrl = 'https://news.google.com/rss/search';

  static Future<List<NewsArticle>> fetchNews(String passionName) async {
    final query = Uri.encodeComponent(passionName);
    final uri   = Uri.parse('$_baseUrl?q=$query&hl=fr&gl=FR&ceid=FR:fr');

    try {
      final response = await http
          .get(uri, headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];

      final document = XmlDocument.parse(response.body);
      final items    = document.findAllElements('item');

      final articles = items.map((item) {
        final title      = _cleanText(item.findElements('title').firstOrNull?.innerText ?? '');
        final link       = item.findElements('link').firstOrNull?.innerText ?? '';
        final pubDate    = item.findElements('pubDate').firstOrNull?.innerText ?? '';
        final sourceEl   = item.findElements('source').firstOrNull;
        final source     = sourceEl?.innerText ?? '';
        final sourceUrl  = sourceEl?.getAttribute('url') ?? '';

        return NewsArticle(
          title:       title,
          source:      source,
          sourceUrl:   sourceUrl,
          url:         link,
          publishedAt: _parseDate(pubDate),
        );
      }).where((a) => a.title.isNotEmpty && a.url.isNotEmpty).toList();

      // Tri par date décroissante (plus récent en premier)
      articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

      return articles;
    } catch (e) {
      debugPrint('[NewsService] error: $e');
      return [];
    }
  }

  // Supprime les balises HTML résiduelles du texte brut
  static String _cleanText(String raw) {
    return raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  static DateTime _parseDate(String raw) {
    try {
      return DateTime.parse(raw);
    } catch (_) {
      try {
        return HttpDate.parse(raw);
      } catch (_) {
        return DateTime.now();
      }
    }
  }
}

// ── Minimal RFC 822 date parser ───────────────────────────────────────────────
class HttpDate {
  static DateTime parse(String date) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
      'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
      'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final parts = date.split(' ');
    if (parts.length < 5) throw FormatException('Invalid date: $date');
    final day   = int.parse(parts[1]);
    final month = months[parts[2]] ?? 1;
    final year  = int.parse(parts[3]);
    final time  = parts[4].split(':');
    return DateTime.utc(
      year, month, day,
      int.parse(time[0]),
      int.parse(time[1]),
      time.length > 2 ? int.parse(time[2]) : 0,
    );
  }
}
