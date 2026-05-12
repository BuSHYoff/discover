import 'package:discover/core/api/api_client.dart';
import 'package:discover/features/nearby/models/nearby_place.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NEARBY SERVICE — passe par le backend NestJS (`GET /passions/:id/nearby`)
//
// L'ancienne version appelait directement Google Places avec la clé embarquée
// dans l'APK — exfiltrable en 30 sec via décompilation. Maintenant la clé vit
// uniquement côté serveur (Secret Manager en prod) et le backend mutualise un
// cache mémoire 10 min normalisé sur ~1 km, pour limiter les coûts Google.
//
// Le client garde un cache local minimal pour éviter de re-fetcher quand
// l'utilisateur revient sur l'écran avec les mêmes params.
// ─────────────────────────────────────────────────────────────────────────────

class _CacheEntry {
  final List<NearbyPlace> places;
  final double            radiusKm;
  _CacheEntry(this.places, this.radiusKm);
}

class NearbyService {
  NearbyService._();

  // Cache local : clé = passionId. Invalide quand l'user demande un rayon
  // supérieur à celui déjà chargé.
  static final Map<String, _CacheEntry> _cache = {};

  /// Cherche les lieux liés à [passionId] autour de (lat, lng).
  ///
  /// `passionName` n'est plus envoyé : le backend résout le nom depuis
  /// l'ID Firestore (source de vérité). Kept en paramètre pour rester
  /// compatible avec l'appelant existant — il sera ignoré.
  static Future<List<NearbyPlace>> search({
    required String passionId,
    required double lat,
    required double lng,
    required double radiusKm,
    String? passionName, // legacy, ignoré
  }) async {
    final cached = _cache[passionId];
    if (cached != null && cached.radiusKm >= radiusKm) {
      return cached.places;
    }

    final raw = await ApiClient.get<List<dynamic>>(
      '/passions/$passionId/nearby',
      query: {
        'lat':    lat,
        'lng':    lng,
        'radius': radiusKm,
      },
      auth: false, // route publique côté backend
    );

    final places = raw
        .whereType<Map>()
        .map((e) => NearbyPlace.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.name.isNotEmpty)
        .toList();

    _cache[passionId] = _CacheEntry(places, radiusKm);
    return places;
  }

  /// Vide le cache pour une passion donnée (utile sur pull-to-refresh).
  static void invalidate(String passionId) => _cache.remove(passionId);
}
