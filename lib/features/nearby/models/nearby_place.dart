// ─────────────────────────────────────────────────────────────────────────────
// NEARBY PLACE — modèle retourné par Google Places TextSearch v1
// ─────────────────────────────────────────────────────────────────────────────

class NearbyPlace {
  final String        id;
  final String        name;
  final String        address;
  final double?       rating;
  final String?       websiteUri;
  final String?       phoneNumber;
  final double        latitude;
  final double        longitude;
  final List<String>  types;
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

  factory NearbyPlace.fromJson(Map<String, dynamic> j) {
    final loc     = j['location'] as Map<String, dynamic>? ?? {};
    final display = j['displayName'] as Map<String, dynamic>? ?? {};
    final hours   = j['regularOpeningHours'] as Map<String, dynamic>?;

    return NearbyPlace(
      id:          j['id'] as String? ?? '',
      name:        display['text'] as String? ?? '',
      address:     j['formattedAddress'] as String? ?? '',
      latitude:    (loc['latitude']  as num?)?.toDouble() ?? 0,
      longitude:   (loc['longitude'] as num?)?.toDouble() ?? 0,
      rating:      (j['rating'] as num?)?.toDouble(),
      websiteUri:  j['websiteUri'] as String?,
      phoneNumber: j['nationalPhoneNumber'] as String?,
      types:       (j['types'] as List<dynamic>?)
                       ?.map((t) => t as String)
                       .toList() ?? [],
      openNow:     hours?['openNow'] as bool?,
    );
  }
}
