import 'package:discover/core/api/api_client.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/core/models/trending.dart';

// Re-export pour ne pas casser les écrans qui font `import trending_service.dart`
// et utilisent `TrendItem` ou `WeeklyPassion`.
export 'package:discover/core/models/trending.dart' show TrendItem, WeeklyPassion, PassionStats;

// ─────────────────────────────────────────────────────────────────────────────
// TRENDING SERVICE
// `GET /trending` côté backend renvoie déjà les 5 passions triées par
// trendScore, avec fallback "fillers" si moins de 5 passions ont des stats.
// On expose la même API qu'avant (`fetchTrends`) pour les écrans.
// ─────────────────────────────────────────────────────────────────────────────

class TrendingService {
  TrendingService._();

  /// Récupère le top des passions tendance.
  /// Le `limit` est ignoré côté backend (fixe à 5) — on tronque si besoin.
  static Future<List<TrendItem>> fetchTrends({int limit = 5}) async {
    try {
      final raw = await ApiClient.get<List<dynamic>>('/trending', auth: false);
      final items = raw
          .whereType<Map>()
          .map((e) => Passion.fromJson(Map<String, dynamic>.from(e)))
          .map((p) => TrendItem(passion: p))
          .toList();
      return items.length > limit ? items.sublist(0, limit) : items;
    } catch (_) {
      return const [];
    }
  }

  /// Lit la passion de la semaine. Renvoie null si pas configurée ou erreur.
  static Future<WeeklyPassion?> fetchWeeklyPassion() async {
    try {
      final json = await ApiClient.get<Map<String, dynamic>>(
        '/trending/weekly-passion',
        auth: false,
      );
      return WeeklyPassion.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
