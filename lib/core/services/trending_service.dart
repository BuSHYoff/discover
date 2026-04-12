import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:discover/core/models/passion.dart';

// ─── Modèle de tendance ───────────────────────────────────────────────────────

class TrendItem {
  final String passionId;
  final int    postsCount;
  final int    likesCount;
  final int    commentsCount;
  final double trendScore;

  const TrendItem({
    required this.passionId,
    required this.postsCount,
    required this.likesCount,
    required this.commentsCount,
    required this.trendScore,
  });

  factory TrendItem.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TrendItem(
      passionId:     doc.id,
      postsCount:    (d['postsCount']    as num?)?.toInt() ?? 0,
      likesCount:    (d['likesCount']    as num?)?.toInt() ?? 0,
      commentsCount: (d['commentsCount'] as num?)?.toInt() ?? 0,
      trendScore:    (d['trendScore']    as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Passion associée (null si l'ID n'est plus dans le catalogue).
  Passion? get passion => PassionRepository.instance.passions
      .where((p) => p.id == passionId)
      .firstOrNull;
}

// ─── Service ──────────────────────────────────────────────────────────────────

class TrendingService {
  static final _db = FirebaseFirestore.instance;

  /// Retourne toujours exactement [limit] items.
  /// Ceux qui ont de l'activité apparaissent en premier (trendScore desc).
  /// Les slots restants sont complétés avec des passions du catalogue (score 0).
  static Future<List<TrendItem>> fetchTrends({int limit = 5}) async {
    // ── 1. Essaie de charger les stats depuis Firestore ──────────────────────
    List<TrendItem> fromFirestore = [];
    try {
      final snap = await _db
          .collection('passions_stats')
          .orderBy('trendScore', descending: true)
          .limit(limit)
          .get();

      fromFirestore = snap.docs
          .map(TrendItem.fromDoc)
          .where((t) => t.passion != null)
          .toList();
    } catch (_) {
      // Collection vide ou index manquant → on continue avec la liste vide
    }

    // ── 2. Complète jusqu'à [limit] avec des passions du catalogue ───────────
    final seenIds = fromFirestore.map((t) => t.passionId).toSet();
    final catalog = PassionRepository.instance.passions;

    for (final passion in catalog) {
      if (fromFirestore.length >= limit) break;
      if (seenIds.contains(passion.id)) continue;
      fromFirestore.add(TrendItem(
        passionId:     passion.id,
        postsCount:    0,
        likesCount:    0,
        commentsCount: 0,
        trendScore:    0,
      ));
      seenIds.add(passion.id);
    }

    return fromFirestore;
  }
}
