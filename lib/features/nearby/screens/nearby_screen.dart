import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/core/theme/app_theme.dart';
import 'package:discover/features/nearby/models/nearby_place.dart';
import 'package:discover/features/nearby/services/nearby_service.dart';
import 'package:discover/features/nearby/widgets/nearby_place_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NEARBY SCREEN — "Autour de moi"
// Rayon fixe : 50 km — un seul appel API à l'ouverture.
// ─────────────────────────────────────────────────────────────────────────────

/// Coordonnées approximatives par code pays ISO-2 (fallback si pas de géoloc)
const Map<String, LatLng> _countryCenters = {
  'fr': LatLng(46.2276,  2.2137),   'us': LatLng(37.0902, -95.7129),
  'gb': LatLng(55.3781,  -3.4360),  'de': LatLng(51.1657,  10.4515),
  'it': LatLng(41.8719,  12.5674),  'es': LatLng(40.4637,  -3.7492),
  'jp': LatLng(36.2048, 138.2529),  'cn': LatLng(35.8617, 104.1954),
  'br': LatLng(-14.235, -51.9253),  'au': LatLng(-25.274, 133.7751),
  'ca': LatLng(56.1304,-106.3468),  'ru': LatLng(61.5240, 105.3188),
  'in': LatLng(20.5937,  78.9629),  'mx': LatLng(23.6345,-102.5528),
  'kr': LatLng(35.9078, 127.7669),  'th': LatLng(15.8700, 100.9925),
  'pt': LatLng(39.3999,  -8.2245),  'nl': LatLng(52.1326,   5.2913),
  'be': LatLng(50.5039,   4.4699),  'ch': LatLng(46.8182,   8.2275),
  'se': LatLng(60.1282,  18.6435),  'no': LatLng(60.4720,   8.4689),
  'dk': LatLng(56.2639,   9.5018),  'pl': LatLng(51.9194,  19.1451),
  'gr': LatLng(39.0742,  21.8243),  'za': LatLng(-30.559,  22.9375),
  'ng': LatLng( 9.0820,   8.6753),  'eg': LatLng(26.8206,  30.8025),
};

class NearbyScreen extends StatefulWidget {
  final Passion passion;
  const NearbyScreen({super.key, required this.passion});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {

  static const double _radius = 50.0;

  // ── État ────────────────────────────────────────────────────────────────────
  List<NearbyPlace>          _places        = [];
  bool                       _loading       = false;
  String?                    _error;
  Position?                  _position;
  NearbyPlace?               _selectedPlace;

  // ── Contrôleurs ─────────────────────────────────────────────────────────────
  final MapController                  _mapCtrl   = MapController();
  final DraggableScrollableController  _sheetCtrl = DraggableScrollableController();
  final TextEditingController          _searchCtrl = TextEditingController();
  String                               _searchQuery = '';

  // ── Lieux filtrés ────────────────────────────────────────────────────────────
  List<NearbyPlace> get _filtered {
    if (_searchQuery.isEmpty) return _places;
    final q = _searchQuery.toLowerCase();
    return _places.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.address.toLowerCase().contains(q)).toList();
  }

  // ── Init ────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text);
      // Ouvre la sheet en haut quand on commence à taper
      if (_searchCtrl.text.isNotEmpty && _sheetCtrl.isAttached) {
        _sheetCtrl.animateTo(0.88,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final pos = await _getPosition();
    if (pos == null) return;
    setState(() => _position = pos);
    // Centrage sur la vraie position une fois la carte rendue
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapCtrl.move(LatLng(pos.latitude, pos.longitude), 12);
      }
    });
    await _fetch();
  }

  // ── Géolocalisation ─────────────────────────────────────────────────────────
  Future<Position?> _getPosition() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      setState(() => _error = 'permission_denied');
      return null;
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
    } catch (e) {
      setState(() => _error = 'location_error');
      return null;
    }
  }

  // ── Fetch ───────────────────────────────────────────────────────────────────
  Future<void> _fetch() async {
    final pos = _position;
    if (pos == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final places = await NearbyService.search(
        passionName: widget.passion.name,
        passionId:   widget.passion.id,
        lat:         pos.latitude,
        lng:         pos.longitude,
        radiusKm:    _radius,
      );
      // Tri par distance croissante depuis la position de l'utilisateur
      final sorted = [...places];
      if (_position != null) {
        final pos = _position!;
        sorted.sort((a, b) {
          final da = Geolocator.distanceBetween(
              pos.latitude, pos.longitude, a.latitude, a.longitude);
          final db = Geolocator.distanceBetween(
              pos.latitude, pos.longitude, b.latitude, b.longitude);
          return da.compareTo(db);
        });
      }
      setState(() { _places = sorted; _loading = false; });
    } catch (e) {
      debugPrint('[NearbyScreen] erreur fetch: $e');
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Re-centrer ───────────────────────────────────────────────────────────────
  void _recenter() {
    final pos = _position;
    if (pos == null) return;
    HapticFeedback.lightImpact();
    _mapCtrl.move(LatLng(pos.latitude, pos.longitude), 13);
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final primary    = Theme.of(context).colorScheme.primary;
    final light      = Color.lerp(primary, Colors.white, 0.88)!;
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(children: [

          // ── App bar ─────────────────────────────────────────────────────
          Container(
            color: AppColors.cream,
            padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Autour de moi',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  Text(widget.passion.name,
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 12, color: AppColors.inkSoft)),
                ]),
              ),
            ]),
          ),

          // ── Carte + overlays ─────────────────────────────────────────────
          Expanded(child: _buildMapStack(primary, light)),
        ]),
      ),
    );
  }

  Widget _buildMapStack(Color primary, Color light) {
    // États sans carte
    if (_error == 'permission_denied') {
      return Container(color: AppColors.cream,
          child: _EmptyState(
            icon: Icons.location_off_rounded, primary: primary, light: light,
            title: 'Localisation désactivée',
            message: 'Active la localisation dans les réglages.',
            action: () async => Geolocator.openLocationSettings(),
            actionLabel: 'Ouvrir les réglages',
          ));
    }
    if (_loading && _position == null) {
      return Container(color: AppColors.cream,
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: primary, strokeWidth: 2),
            const SizedBox(height: 14),
            Text('Localisation en cours…',
                style: GoogleFonts.firaSansCondensed(fontSize: 14, color: AppColors.inkSoft)),
          ])));
    }

    // Fallback : pays de l'activité si pas encore de position
    final countryCode = widget.passion.country.toLowerCase();
    final fallback    = _countryCenters[countryCode] ?? const LatLng(46.2276, 2.2137);
    final center = _position != null
        ? LatLng(_position!.latitude, _position!.longitude)
        : fallback;
    final initialZoom = _position != null ? 12.0 : 5.0;

    return Stack(children: [

      // ── Carte OSM ─────────────────────────────────────────────────────
      FlutterMap(
        mapController: _mapCtrl,
        options: MapOptions(
          initialCenter: center,
          initialZoom: initialZoom,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          onTap: (_, __) {
            if (_selectedPlace != null) {
              setState(() => _selectedPlace = null);
            } else if (_sheetCtrl.isAttached) {
              _sheetCtrl.animateTo(0.14,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut);
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.baptiste.discover',
          ),
          MarkerLayer(markers: [
            // Ma position
            if (_position != null)
              Marker(
                point: LatLng(_position!.latitude, _position!.longitude),
                width: 22, height: 22,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    border: Border.all(color: primary, width: 3),
                    boxShadow: [BoxShadow(
                      color: primary.withValues(alpha: 0.4),
                      blurRadius: 8, spreadRadius: 1,
                    )],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                  ),
                ),
              ),

            // Lieux
            ..._places.map((place) {
              final selected = _selectedPlace?.id == place.id;
              return Marker(
                point: LatLng(place.latitude, place.longitude),
                width: 32, height: 32,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedPlace = place);
                    _mapCtrl.move(LatLng(place.latitude, place.longitude), 14);
                  },
                  child: Icon(
                    Icons.location_on_rounded,
                    size: selected ? 36 : 28,
                    color: selected ? Colors.white : primary,
                    shadows: [Shadow(
                      color: Colors.black.withValues(alpha: selected ? 0.35 : 0.2),
                      blurRadius: selected ? 6 : 4,
                      offset: const Offset(0, 2),
                    )],
                  ),
                ),
              );
            }),
          ]),
        ],
      ),

      // ── Badge nombre de lieux (haut gauche) ───────────────────────────
      if (_places.isNotEmpty)
        Positioned(
          top: 12, left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8, offset: const Offset(0, 2),
              )],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.place_rounded, size: 13, color: primary),
              const SizedBox(width: 4),
              Text('${_places.length} lieu${_places.length > 1 ? 'x' : ''}',
                  style: GoogleFonts.firaSansCondensed(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
            ]),
          ),
        ),

      // ── Indicateur chargement ──────────────────────────────────────────
      if (_loading)
        Positioned(
          top: 12, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8, offset: const Offset(0, 2),
                )],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 12, height: 12,
                    child: CircularProgressIndicator(color: primary, strokeWidth: 2)),
                const SizedBox(width: 8),
                Text('Recherche…',
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ]),
            ),
          ),
        ),

      // ── Bouton re-centrer (bas droite, au-dessus de la sheet) ─────────
      Positioned(
        bottom: 200, right: 14,
        child: GestureDetector(
          onTap: _recenter,
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10, offset: const Offset(0, 3),
              )],
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Icon(Icons.my_location_rounded, color: primary, size: 22),
          ),
        ),
      ),

      // ── Bottom sheet liste OU card lieu sélectionné ───────────────────
      if (_selectedPlace != null)
        _buildSelectedCard(primary)
      else
        _buildBottomSheet(primary, light),
    ]);
  }

  // ── Bottom sheet avec recherche + liste ─────────────────────────────────────
  Widget _buildBottomSheet(Color primary, Color light) {
    return DraggableScrollableSheet(
      controller: _sheetCtrl,
      initialChildSize: 0.38,
      minChildSize: 0.14,
      maxChildSize: 0.88,
      snap: true,
      snapSizes: const [0.14, 0.38, 0.88],
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20, offset: const Offset(0, -4),
            )],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Poignée
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(children: [
                  Text(
                    _loading
                        ? 'Recherche en cours…'
                        : '${_filtered.length} résultat${_filtered.length > 1 ? 's' : ''}',
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                ]),
              ),

              // Barre de recherche
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search_rounded, size: 18, color: AppColors.inkSoft),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 14, color: AppColors.ink),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un lieu…',
                          hintStyle: GoogleFonts.firaSansCondensed(
                              fontSize: 14, color: AppColors.inkFaint),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () => _searchCtrl.clear(),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Icon(Icons.close_rounded,
                              size: 16, color: AppColors.inkSoft),
                        ),
                      ),
                  ]),
                ),
              ),

              // Loading / vide / liste
              if (_loading && _places.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  child: Column(children: [
                    Icon(Icons.search_off_rounded, size: 32, color: AppColors.inkFaint),
                    const SizedBox(height: 10),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Aucun lieu pour "${_searchCtrl.text}"'
                          : 'Aucun lieu trouvé dans un rayon de 50 km',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 14, color: AppColors.inkSoft, height: 1.4),
                    ),
                  ]),
                )
              else
                ..._filtered.map((place) => GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedPlace = place);
                    _mapCtrl.move(LatLng(place.latitude, place.longitude), 14);
                  },
                  child: NearbyPlaceCard(
                    place: place,
                    primaryColor: primary,
                    distanceMeters: _distanceFor(place),
                  ),
                )),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  double? _distanceFor(NearbyPlace place) {
    final pos = _position;
    if (pos == null) return null;
    return Geolocator.distanceBetween(
        pos.latitude, pos.longitude, place.latitude, place.longitude);
  }

  // ── Card lieu sélectionné ────────────────────────────────────────────────────
  Widget _buildSelectedCard(Color primary) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: NearbyPlaceCard(
          place: _selectedPlace!,
          primaryColor: primary,
          distanceMeters: _distanceFor(_selectedPlace!),
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData     icon;
  final String       title;
  final String       message;
  final Color        primary;
  final Color        light;
  final VoidCallback? action;
  final String?      actionLabel;

  const _EmptyState({
    required this.icon, required this.title, required this.message,
    required this.primary, required this.light,
    this.action, this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: light, shape: BoxShape.circle),
            child: Icon(icon, color: primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.firaSansCondensed(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.firaSansCondensed(
                  fontSize: 13.5, color: AppColors.inkSoft, height: 1.5)),
          if (action != null && actionLabel != null) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: action,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                    color: primary, borderRadius: BorderRadius.circular(100)),
                child: Text(actionLabel!,
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 13.5, fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
