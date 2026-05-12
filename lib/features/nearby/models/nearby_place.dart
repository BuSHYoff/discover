// ─────────────────────────────────────────────────────────────────────────────
// NEARBY PLACE — modèle aligné sur backend/src/nearby/entities/nearby-place.entity.ts
//
// Le backend normalise la réponse Google Places en un format plat avant de la
// renvoyer au client. Si on change de provider (OpenTripMap, Foursquare…),
// ce modèle ne change pas — seul le service backend de mapping change.
// ─────────────────────────────────────────────────────────────────────────────

class NearbyPlace {
  final String        id;
  final String        name;
  final String        address;
  final double        latitude;
  final double        longitude;
  final List<String>  types;
  final double?       rating;
  final String?       websiteUri;
  final String?       phoneNumber;
  final bool?         openNow;

  const NearbyPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.types,
    this.rating,
    this.websiteUri,
    this.phoneNumber,
    this.openNow,
  });

  factory NearbyPlace.fromJson(Map<String, dynamic> j) => NearbyPlace(
    id:          j['id']          as String? ?? '',
    name:        j['name']        as String? ?? '',
    address:     j['address']     as String? ?? '',
    latitude:    (j['latitude']  as num?)?.toDouble() ?? 0,
    longitude:   (j['longitude'] as num?)?.toDouble() ?? 0,
    types:       (j['types'] as List<dynamic>?)
                     ?.map((t) => t as String)
                     .toList() ?? const [],
    rating:      (j['rating'] as num?)?.toDouble(),
    websiteUri:  j['websiteUri']  as String?,
    phoneNumber: j['phoneNumber'] as String?,
    openNow:     j['openNow']     as bool?,
  );
}
