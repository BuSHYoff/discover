// ─────────────────────────────────────────────────────────────────────────────
// Modèles Trending — alignés sur backend/src/trending/entities/*.entity.ts
// ─────────────────────────────────────────────────────────────────────────────

import 'package:discover/core/models/passion.dart';

class PassionStats {
  final String passionId;
  final int    postsCount;
  final int    likesCount;
  final int    commentsCount;
  final double trendScore;

  const PassionStats({
    required this.passionId,
    required this.postsCount,
    required this.likesCount,
    required this.commentsCount,
    required this.trendScore,
  });

  factory PassionStats.fromJson(Map<String, dynamic> j) => PassionStats(
    passionId:     j['passionId']     as String? ?? '',
    postsCount:    (j['postsCount']    as num?)?.toInt() ?? 0,
    likesCount:    (j['likesCount']    as num?)?.toInt() ?? 0,
    commentsCount: (j['commentsCount'] as num?)?.toInt() ?? 0,
    trendScore:    (j['trendScore']    as num?)?.toDouble() ?? 0.0,
  );
}

/// Item de tendance — combine la passion (résolue côté backend) + ses stats
/// dérivées si elles existent.
///
/// `GET /trending` du backend renvoie directement la liste des Passion
/// triées par trendScore. Les `*Count` sont déduits du score, optionnels.
class TrendItem {
  final Passion passion;

  const TrendItem({required this.passion});

  String get passionId => passion.id;
}

/// Réponse de `GET /trending/weekly-passion`.
class WeeklyPassion {
  final Passion passion;
  final String  description;

  const WeeklyPassion({required this.passion, required this.description});

  factory WeeklyPassion.fromJson(Map<String, dynamic> j) => WeeklyPassion(
    passion:     Passion.fromJson(Map<String, dynamic>.from(j['passion'] as Map)),
    description: j['description'] as String? ?? '',
  );
}
