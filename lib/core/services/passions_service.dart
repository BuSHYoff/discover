import 'package:discover/core/api/api_client.dart';
import 'package:discover/core/models/passion.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PASSIONS SERVICE
//
// Cache mémoire en 2 couches :
//   1. `_cached` : List<Passion> chargée au boot via /passions (light + browsing).
//      Reste valide toute la session.
//   2. `_journeyCache` : Map<passionId, PassionJourney> remplie à la demande
//      quand l'user ouvre une passion. Aucune expiration côté session — un
//      re-clic = read instantané, pas de spam réseau.
//
// Le backend re-cache déjà 5 min côté serveur ; le cache client supplémentaire
// économise même cette latence + ~2 KB par requête.
// ─────────────────────────────────────────────────────────────────────────────

class PassionsService {
  PassionsService._();

  static List<Passion>             _cached        = const [];
  static Map<String, PassionJourney> _journeyCache = {};
  static bool _loaded = false;

  /// Liste statique des passions (vide tant que `loadCatalog` n'a pas tourné).
  static List<Passion> get cached => _cached;
  static bool get isLoaded => _loaded;

  /// Charge le catalogue light depuis `GET /passions`. À appeler au boot.
  /// Idempotent : si déjà chargé, no-op (passe `force: true` pour recharger).
  static Future<void> loadCatalog({bool force = false}) async {
    if (_loaded && !force) return;
    final raw = await ApiClient.get<List<dynamic>>('/passions', auth: false);
    _cached = raw
        .whereType<Map>()
        .map((e) => Passion.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    _loaded = true;
  }

  /// Réinitialise tous les caches (utile à la déconnexion).
  static void clearCache() {
    _cached        = const [];
    _journeyCache  = {};
    _loaded        = false;
  }

  /// Vide uniquement le cache journey (par ex. après un edit admin).
  static void clearJourneyCache() {
    _journeyCache = {};
  }

  /// Retourne une passion depuis le cache, ou null si inconnue.
  static Passion? find(String id) {
    for (final p in _cached) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Fetch une passion en direct depuis le backend (bypass cache).
  static Future<Passion> fetchOne(String id) async {
    final json = await ApiClient.get<Map<String, dynamic>>(
      '/passions/$id',
      auth: false,
    );
    return Passion.fromJson(json);
  }

  /// Récupère le contenu journey d'une passion.
  /// 1er appel → GET /passions/:id/journey, puis cache mémoire jusqu'à la fin
  /// de la session. Les appels suivants sont synchrones (ms).
  static Future<PassionJourney> fetchJourney(String passionId) async {
    final cached = _journeyCache[passionId];
    if (cached != null) return cached;

    final json = await ApiClient.get<Map<String, dynamic>>(
      '/passions/$passionId/journey',
      auth: false,
    );
    final journey = PassionJourney.fromJson(json);
    _journeyCache[passionId] = journey;
    return journey;
  }
}

// ─── Compat : ancien API AIContentProvider.getFor(id) ────────────────────────
//
// Beaucoup d'écrans appellent `AIContentProvider.getFor(passionId)`. On garde
// la même surface : on merge Passion (du cache) + PassionJourney (à la demande)
// en un seul AIContent.

class AIContentProvider {
  AIContentProvider._();

  /// Retourne le contenu IA mergé d'une passion. Si la passion n'est pas dans
  /// le catalogue (cas exceptionnel), renvoie un objet vide.
  static Future<AIContent> getFor(String passionId) async {
    final passion = PassionsService.find(passionId);
    if (passion == null) {
      return const AIContent(
        id:        '',
        tagline:   '',
        steps:     [],
        materials: [],
        tips:      [],
        resources: [],
      );
    }

    final journey = await PassionsService.fetchJourney(passionId);
    return AIContent(
      id:        passion.id,
      tagline:   passion.tagline,
      // Champs journey
      steps:     journey.steps,
      materials: journey.materials,
      topVideos: journey.topVideos,
      // Champs light
      tips:      passion.tips,
      resources: passion.resources,
      shorts:    passion.shorts,
    );
  }
}
