import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:country_flags/country_flags.dart';
import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/features/map/widgets/country_card.dart';
import 'package:discover/features/map/widgets/detail_legend.dart';
import 'package:discover/features/map/widgets/country_passions_sheet.dart';
import 'package:discover/core/theme/app_theme.dart';

// ─── WORLD ORIGIN SCREEN ──────────────────────────────────────────────────────
//
// DEUX MODES :
//
// 1. Mode "exploration" (nav bar) → MapScreen()
//    Charge passions.json, colore tous les pays ayant des passions en vert.
//    Au tap sur un pays vert → overlay Stack avec card (nom pays, nb passions,
//    "En savoir plus"). Clic sur "En savoir plus" → bottom sheet avec liste
//    scrollable de toutes les passions du pays (style profile_screen).
//
// 2. Mode "carte" (fiche détail) → MapScreen(highlightCountry: 'FR')
//    Un seul pays vert animé, tous les autres grisés, légende en bas.

const double _kBottomBarHeight       = 72.0;
const double _kBottomBarExtraPadding = 16.0;

class MapScreen extends StatefulWidget {
  final String? highlightCountry;
  final String? excludePassionId;
  const MapScreen({super.key, this.highlightCountry, this.excludePassionId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {

  String? _tappedId;
  String? _tappedName;
  final TransformationController _transformCtrl = TransformationController();
  bool _autoZoomed = false;

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  // countryCode (uppercase) → list of Passion objects
  Map<String, List<Passion>> _countryPassions = {};
  bool _loading = true;

  bool get _isExploreMode => widget.highlightCountry == null;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.50, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    if (_isExploreMode) {
      _loadPassions();
    } else {
      // En mode détail, charger aussi les passions pour ouvrir la sheet
      _loadPassions(thenOpenSheet: true);
    }
  }

  Future<void> _loadPassions({bool thenOpenSheet = false}) async {
    final map = <String, List<Passion>>{};
    for (final passion in allPassions) {
      final code = passion.country.trim().toUpperCase();
      if (code.isNotEmpty) {
        map.putIfAbsent(code, () => []).add(passion);
      }
    }

    if (mounted) {
      setState(() { _countryPassions = map; _loading = false; });

      if (thenOpenSheet && widget.highlightCountry != null) {
        final code = widget.highlightCountry!.toUpperCase();
        final passions = map[code] ?? [];
        // Ouvrir uniquement s'il y a d'AUTRES activités dans ce pays
        if (passions.length > 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openPassionSheet(code, _countryName(code));
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  void _openPassionSheet(String countryCode, String countryName) {
    // En mode explore : toutes les passions du pays
    // En mode détail : on exclut la passion courante
    final passions = _isExploreMode
        ? (_countryPassions[countryCode] ?? [])
        : (_countryPassions[countryCode] ?? [])
        .where((p) => p.id != widget.excludePassionId)
        .toList();
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CountryPassionsSheet(
        countryName: countryName,
        countryCode: countryCode,
        passions: passions,
        isExploreMode: _isExploreMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding    = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final extraBottom   = _isExploreMode
        ? _kBottomBarHeight + bottomPadding + _kBottomBarExtraPadding
        : 0.0;

    final primary = Theme.of(context).colorScheme.primary;

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
            child: CircularProgressIndicator(color: primary, strokeWidth: 2)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(children: [
        _buildHeader(topPadding, primary),
        Expanded(
          child: Stack(
            children: [
              // ── CARTE (fond) ───────────────────────────────────────────
              Positioned.fill(child: _buildMap()),

              // ── OVERLAY CARD (mode explore, pays tapé) ─────────────────
              if (_isExploreMode && _tappedId != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: extraBottom + 12,
                  child: CountryCard(
                    countryCode: _tappedId!,
                    countryName: _countryName(_tappedId!),
                    passionCount: (_countryPassions[_tappedId] ?? []).length,
                    onLearnMore: () => _openPassionSheet(
                        _tappedId!, _countryName(_tappedId!)),
                  ),
                ),

              // ── LÉGENDE mode détail (overlay bas) ─────────────────────
              if (!_isExploreMode)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: bottomPadding + 16,
                  child: DetailLegend(
                    countryName:
                    _countryName(widget.highlightCountry!),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader(double topPadding, Color primary) {
    final highlight = widget.highlightCountry;
    final label     = highlight != null ? _countryName(highlight) : null;

    return Container(
      color: AppColors.cream,
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 16),
      child: Row(children: [
        // FIX : bouton retour uniquement en mode détail (poussé via Navigator.push)
        if (widget.highlightCountry != null) ...[
          GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); Navigator.of(context).pop(); },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
                boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(
              TextSpan(
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                    height: 1.05),
                children: [
                  const TextSpan(text: 'Carte'),
                  TextSpan(text: '.', style: TextStyle(color: primary)),
                ],
              ),
            ),
            if (_isExploreMode)
              Text(
                '${_countryPassions.length} pays représentés',
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.inkSoft,
                    letterSpacing: -0.1),
              ),
          ]),
        ),
        if (highlight != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CountryFlag.fromCountryCode(
              highlight,
              theme: const ImageTheme(width: 42, height: 28),
            ),
          ),
      ]),
    );
  }

  // ── CARTE ─────────────────────────────────────────────────────────────────
  // Centroïdes des pays en fraction 0..1 du SVG monde (dx, dy)
  static const _kCentroids = <String, (double, double)>{
    'FR': (0.468, 0.295), 'DE': (0.492, 0.248), 'GB': (0.452, 0.228),
    'IT': (0.502, 0.310), 'ES': (0.452, 0.318), 'PT': (0.433, 0.320),
    'NL': (0.476, 0.222), 'BE': (0.472, 0.234), 'CH': (0.482, 0.268),
    'AT': (0.498, 0.258), 'PL': (0.510, 0.238), 'SE': (0.494, 0.175),
    'NO': (0.482, 0.162), 'FI': (0.521, 0.168), 'DK': (0.481, 0.208),
    'GR': (0.518, 0.318), 'RU': (0.622, 0.198), 'UA': (0.532, 0.252),
    'TR': (0.548, 0.292), 'SA': (0.572, 0.368), 'IR': (0.590, 0.318),
    'IQ': (0.564, 0.318), 'IL': (0.543, 0.318), 'AE': (0.594, 0.362),
    'KZ': (0.618, 0.252), 'PK': (0.624, 0.338), 'IN': (0.638, 0.392),
    'BD': (0.672, 0.378), 'LK': (0.648, 0.452), 'NP': (0.652, 0.332),
    'CN': (0.718, 0.318), 'JP': (0.802, 0.302), 'KR': (0.788, 0.302),
    'TH': (0.706, 0.418), 'VN': (0.724, 0.412), 'KH': (0.718, 0.432),
    'MM': (0.698, 0.392), 'MY': (0.728, 0.462), 'ID': (0.748, 0.508),
    'PH': (0.762, 0.432), 'AU': (0.788, 0.642), 'NZ': (0.872, 0.712),
    'US': (0.198, 0.298), 'CA': (0.182, 0.202), 'MX': (0.194, 0.368),
    'BR': (0.292, 0.548), 'AR': (0.268, 0.658), 'CL': (0.252, 0.632),
    'CO': (0.248, 0.478), 'PE': (0.244, 0.548), 'VE': (0.258, 0.452),
    'CU': (0.224, 0.388), 'EG': (0.534, 0.352), 'MA': (0.450, 0.342),
    'NG': (0.490, 0.472), 'ET': (0.550, 0.462), 'KE': (0.546, 0.498),
    'TZ': (0.544, 0.538), 'ZA': (0.520, 0.662), 'MG': (0.566, 0.592),
  };

  void _zoomToCountry(String code, Size viewSize, {double scale = 4.0}) {
    final centroid = _kCentroids[code.toUpperCase()] ?? (0.5, 0.4);

    final double mapW = viewSize.width;
    final double mapH = mapW * (507.0 / 1000.0);

    // Position du centroïde en pixels dans la carte SVG
    final double cx = centroid.$1 * mapW;
    final double cy = centroid.$2 * mapH;

    // Centre le pays, décalé vers le haut pour laisser place à la bottomsheet (20% écran)
    final double sheetH = viewSize.height * 0.32;
    final double tx = viewSize.width  / 2 - cx * scale;
    final double ty = viewSize.height / 2 - cy * scale - sheetH;

    _transformCtrl.value = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, tx)
      ..setEntry(1, 3, ty);
  }

  Widget _buildMap() {
    final primary = Theme.of(context).colorScheme.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapSize = Size(constraints.maxWidth, constraints.maxHeight);

        // Auto-zoom en mode détail — une seule fois
        if (!_isExploreMode && widget.highlightCountry != null && !_autoZoomed) {
          _autoZoomed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _zoomToCountry(widget.highlightCountry!, mapSize, scale: 5.0);
          });
        }
        // Centrage vertical en mode explore (bottombar)
        if (_isExploreMode && !_autoZoomed) {
          _autoZoomed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final double bottomInset = _kBottomBarHeight +
                _kBottomBarExtraPadding +
                MediaQuery.of(context).padding.bottom;
            final double mapW = constraints.maxWidth;
            final double mapH = mapW * (507.0 / 1000.0);
            // Zoom pour éviter tout bord visible, puis centrage dans la zone
            // visible au-dessus de la bottom bar.
            final double viewH = constraints.maxHeight - bottomInset;
            final double scale = (viewH / mapH).clamp(1.0, 8.0);
            final double scaledW = mapW * scale;
            final double scaledH = mapH * scale;
            final double tx = (constraints.maxWidth - scaledW) / 2;
            final double ty = (viewH - scaledH) / 2;
            _transformCtrl.value = Matrix4.identity()
              ..setEntry(0, 0, scale)
              ..setEntry(1, 1, scale)
              ..setEntry(0, 3, tx)
              ..setEntry(1, 3, ty);
          });
        }

        return AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, _) {
            // La carte SVG a un ratio 1000:507
            final double mapH = constraints.maxWidth * (507.0 / 1000.0);
            return InteractiveViewer(
              transformationController: _transformCtrl,
              minScale: 1.0,
              maxScale: 8.0,
              constrained: false,
              // En mode exploration (bottom bar), on bloque le pan aux dimensions
              // de la carte. En mode détail, on garde la liberté actuelle.
              boundaryMargin: _isExploreMode
                  ? EdgeInsets.zero
                  : const EdgeInsets.all(double.infinity),
              child: SizedBox(
                width: constraints.maxWidth,
                height: mapH,
                child: SimpleMap(
                  instructions: SMapWorld.instructions,
                  defaultColor: AppColors.grey,
                  colors: _buildColors(_pulseAnim.value, primary),
                  callback: (id, name, tapDetails) {
                    HapticFeedback.selectionClick();
                    final code = id.toUpperCase();
                    if (_isExploreMode) {
                      // Mode explore : affiche la CountryCard overlay, pas la sheet
                      if (!_countryPassions.containsKey(code)) {
                        setState(() { _tappedId = null; _tappedName = null; });
                      } else {
                        setState(() { _tappedId = code; _tappedName = _countryName(code); });
                      }
                    } else {
                      // Mode détail (depuis DetailScreen) : ouvre directement la sheet
                      setState(() { _tappedId = code; _tappedName = _countryName(code); });
                      _openPassionSheet(code, _countryName(code));
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Map<String, Color> _buildColors(double pulseValue, Color primary) {
    final animated = Color.lerp(
      primary.withValues(alpha: 0.55),
      primary,
      pulseValue,
    )!;

    if (_isExploreMode) {
      final result = <String, Color>{};
      for (final code in _countryPassions.keys) {
        result[code.toLowerCase()] = animated;
      }
      if (_tappedId != null) {
        result[_tappedId!.toLowerCase()] = primary;
      }
      return result;
    } else {
      return {widget.highlightCountry!.toLowerCase(): animated};
    }
  }
}

// ─── NOMS DES PAYS ────────────────────────────────────────────────────────────

String _countryName(String code) {
  const names = <String, String>{
    'AF': 'Afghanistan',     'AL': 'Albanie',          'DZ': 'Algérie',
    'AO': 'Angola',          'AR': 'Argentine',        'AU': 'Australie',
    'AT': 'Autriche',        'AZ': 'Azerbaïdjan',      'BD': 'Bangladesh',
    'BE': 'Belgique',        'BR': 'Brésil',            'BG': 'Bulgarie',
    'KH': 'Cambodge',        'CM': 'Cameroun',         'CA': 'Canada',
    'CL': 'Chili',           'CN': 'Chine',             'CO': 'Colombie',
    'CD': 'Congo (RDC)',     'CG': 'Congo',             'CR': 'Costa Rica',
    'HR': 'Croatie',         'CU': 'Cuba',              'CZ': 'Tchéquie',
    'DK': 'Danemark',        'DO': 'Rép. Dominicaine', 'EC': 'Équateur',
    'EG': 'Égypte',          'ET': 'Éthiopie',          'FI': 'Finlande',
    'FR': 'France',          'DE': 'Allemagne',         'GH': 'Ghana',
    'GR': 'Grèce',           'GT': 'Guatemala',         'HU': 'Hongrie',
    'IN': 'Inde',            'ID': 'Indonésie',         'IR': 'Iran',
    'IQ': 'Irak',            'IE': 'Irlande',           'IL': 'Israël',
    'IT': 'Italie',          'JP': 'Japon',             'JO': 'Jordanie',
    'KZ': 'Kazakhstan',      'KE': 'Kenya',             'KP': 'Corée du Nord',
    'KR': 'Corée du Sud',    'KW': 'Koweït',            'LA': 'Laos',
    'LB': 'Liban',           'LY': 'Libye',             'MG': 'Madagascar',
    'MY': 'Malaisie',        'ML': 'Mali',              'MX': 'Mexique',
    'MA': 'Maroc',           'MZ': 'Mozambique',        'MM': 'Myanmar',
    'NP': 'Népal',           'NL': 'Pays-Bas',          'NZ': 'Nouvelle-Zélande',
    'NI': 'Nicaragua',       'NG': 'Nigeria',            'NO': 'Norvège',
    'PK': 'Pakistan',        'PA': 'Panama',            'PG': 'Papouasie',
    'PY': 'Paraguay',        'PE': 'Pérou',             'PH': 'Philippines',
    'PL': 'Pologne',         'PT': 'Portugal',          'RO': 'Roumanie',
    'RU': 'Russie',          'SA': 'Arabie Saoudite',   'SN': 'Sénégal',
    'ZA': 'Afrique du Sud',  'ES': 'Espagne',           'LK': 'Sri Lanka',
    'SD': 'Soudan',          'SE': 'Suède',             'CH': 'Suisse',
    'SY': 'Syrie',           'TW': 'Taïwan',            'TZ': 'Tanzanie',
    'TH': 'Thaïlande',       'TN': 'Tunisie',           'TR': 'Turquie',
    'UA': 'Ukraine',         'GB': 'Royaume-Uni',       'US': 'États-Unis',
    'UY': 'Uruguay',         'UZ': 'Ouzbékistan',       'VE': 'Venezuela',
    'VN': 'Vietnam',         'YE': 'Yémen',             'ZM': 'Zambie',
    'ZW': 'Zimbabwe',
  };
  return names[code] ?? code;
}
