import 'package:flutter/foundation.dart';

import 'package:discover/core/api/api_client.dart';
import 'package:discover/core/models/app_user.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STREAK SERVICE
// Wrapper sur GET/POST /users/me/streak.
//
// Cache mémoire de session : 1er fetch → réseau, suivants → instantané.
// Le backend gère déjà la dédup par jour calendaire (UTC), donc on peut
// appeler `tick()` n'importe quand sans crainte de doubles incréments.
// ─────────────────────────────────────────────────────────────────────────────

class StreakService {
  StreakService._();

  static UserStreak? _cached;

  /// État actuel en cache (null tant que `fetch` n'a pas tourné).
  static UserStreak? get cached => _cached;

  /// Récupère le streak depuis le backend. Cache-first :
  /// le 2e appel dans la même session renvoie le cache sans toucher au réseau.
  static Future<UserStreak> fetch({bool forceRefresh = false}) async {
    final cached = _cached;
    if (cached != null && !forceRefresh) return cached;

    try {
      final json = await ApiClient.get<Map<String, dynamic>>('/users/me/streak');
      final streak = UserStreak.fromJson(json);
      _cached = streak;
      return streak;
    } catch (e) {
      if (kDebugMode) debugPrint('[StreakService] fetch: $e');
      // Fallback : retourne un streak vide si l'API échoue. On évite ainsi
      // de bloquer l'UI sur une erreur réseau temporaire.
      return const UserStreak(count: 0);
    }
  }

  /// Tick le streak (à appeler quand l'utilisateur complète un jour journalier).
  /// Le backend est idempotent par date — appels multiples le même jour
  /// renverront tous le même `count`, pas de double comptage.
  static Future<UserStreak> tick() async {
    try {
      final json = await ApiClient.post<Map<String, dynamic>>(
        '/users/me/streak',
        body: const {},
      );
      final streak = UserStreak.fromJson(json);
      _cached = streak;
      return streak;
    } catch (e) {
      if (kDebugMode) debugPrint('[StreakService] tick: $e');
      // En cas d'erreur réseau : on garde le cache courant pour ne pas
      // faire régresser l'UI. Le prochain `fetch` réalignera l'état.
      return _cached ?? const UserStreak(count: 0);
    }
  }

  /// Vide le cache (à appeler au signOut).
  static void clearCache() {
    _cached = null;
  }
}
