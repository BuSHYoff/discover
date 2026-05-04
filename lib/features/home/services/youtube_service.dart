import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// YOUTUBE SERVICE — Data API v3 Shorts
// ─────────────────────────────────────────────────────────────────────────────

class YoutubeShort {
  final String id;
  final String title;
  final String channelName;
  final String thumbnailUrl;

  const YoutubeShort({
    required this.id,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
  });

  String get watchUrl => 'https://www.youtube.com/shorts/$id';

  factory YoutubeShort.fromJson(Map<String, dynamic> j) {
    final snippet    = j['snippet']    as Map<String, dynamic>;
    final thumbs     = snippet['thumbnails'] as Map<String, dynamic>;
    final thumb      = (thumbs['high'] ?? thumbs['medium'] ?? thumbs['default'])
        as Map<String, dynamic>;

    return YoutubeShort(
      id:           (j['id'] as Map<String, dynamic>)['videoId'] as String,
      title:        _decodeHtml(snippet['title']        as String),
      channelName:  _decodeHtml(snippet['channelTitle'] as String),
      thumbnailUrl: thumb['url']                        as String,
    );
  }
}

/// Décode les entités HTML courantes retournées par l'API YouTube.
/// YouTube encode les titres en HTML : &#39; → ' , &amp; → & , &quot; → " , etc.
String _decodeHtml(String text) => text
    .replaceAll('&#39;',  "'")
    .replaceAll('&amp;',  '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&lt;',   '<')
    .replaceAll('&gt;',   '>')
    .replaceAll('&#34;',  '"')
    .replaceAll('&#38;',  '&')
    .replaceAll('&#60;',  '<')
    .replaceAll('&#62;',  '>');

class YoutubeService {
  YoutubeService._();

  // ⚠️  Remplace par ta clé YouTube Data API v3
  static const String _apiKey  = 'AIzaSyAkqj2iEJ9LhWNZd4okDFlw0NdJS-ZcMlM';
  static const String _baseUrl =
      'https://www.googleapis.com/youtube/v3/search';

  // Cache simple : passionId → résultats
  static final Map<String, List<YoutubeShort>> _cache = {};

  static void clearCache() => _cache.clear();

  static Future<List<YoutubeShort>> fetchShorts(
    String passionName,
    String passionId,
  ) async {
    if (_cache.containsKey(passionId)) return _cache[passionId]!;

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'part':             'snippet',
      'q':                passionName,
      'type':             'video',
      'videoDuration':    'short',
      'videoEmbeddable':  'true',   // filtre uniquement les vidéos intégrables
      'maxResults':       '15',
      'key':              _apiKey,
    });

    final response = await http.get(uri);

    debugPrint('[YouTube] status: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception(
          'YouTube API error ${response.statusCode}: ${response.body}');
    }

    final data  = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];

    final shorts = items
        .map((i) => YoutubeShort.fromJson(i as Map<String, dynamic>))
        .where((s) => s.id.isNotEmpty)
        .toList();

    _cache[passionId] = shorts;
    return shorts;
  }
}
