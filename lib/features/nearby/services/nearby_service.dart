import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:discover/features/nearby/models/nearby_place.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NEARBY SERVICE — Google Places TextSearch v1
//
// Cache : les résultats sont conservés tant que l'utilisateur ne relance pas
// un appel avec un rayon PLUS ÉLEVÉ que celui déjà en cache.
// ─────────────────────────────────────────────────────────────────────────────

class _CacheEntry {
  final List<NearbyPlace> places;
  final double            radiusKm;
  _CacheEntry(this.places, this.radiusKm);
}

class NearbyService {
  NearbyService._();

  // ⚠️  Remplace par ta clé Google Places API (Places API (New) activée)
  static const String _apiKey = 'AIzaSyD3b2U8rTrWQRg-2_6Cf5hpxjnKF5DHIJw';

  static const String _baseUrl =
      'https://places.googleapis.com/v1/places:searchText';

  static const String _fieldMask =
      'places.id,'
      'places.displayName,'
      'places.formattedAddress,'
      'places.location,'
      'places.rating,'
      'places.websiteUri,'
      'places.nationalPhoneNumber,'
      'places.types,'
      'places.regularOpeningHours';

  // Cache : clé = passionId
  static final Map<String, _CacheEntry> _cache = {};

  /// Retourne les lieux autour de [lat]/[lng] pour la passion [passionName].
  ///
  /// - Si le cache existe et que son rayon >= [radiusKm] → résultats cachés.
  /// - Si [radiusKm] > rayon en cache → nouvel appel API, cache mis à jour.
  static Future<List<NearbyPlace>> search({
    required String passionName,
    required String passionId,
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final cached = _cache[passionId];
    if (cached != null && cached.radiusKm >= radiusKm) {
      return cached.places;
    }

    final body = jsonEncode({
      'textQuery':      passionName,
      'languageCode':   'fr',
      'maxResultCount': 20,
      'locationBias': {
        'circle': {
          'center': {'latitude': lat, 'longitude': lng},
          'radius': radiusKm * 1000, // mètres
        },
      },
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type':     'application/json',
        'X-Goog-Api-Key':   _apiKey,
        'X-Goog-FieldMask': _fieldMask,
      },
      body: body,
    );

    debugPrint('[NearbyService] status: ${response.statusCode}');
    debugPrint('[NearbyService] body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
          'Places API error ${response.statusCode}: ${response.body}');
    }

    final data   = jsonDecode(response.body) as Map<String, dynamic>;
    final list   = data['places'] as List<dynamic>? ?? [];
    final places = list
        .map((p) => NearbyPlace.fromJson(p as Map<String, dynamic>))
        .where((p) => p.name.isNotEmpty)
        .toList();

    _cache[passionId] = _CacheEntry(places, radiusKm);
    return places;
  }

  /// Vide le cache pour une passion donnée (utile si l'user force le refresh).
  static void invalidate(String passionId) => _cache.remove(passionId);
}
