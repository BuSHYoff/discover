import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:discover/features/nearby/models/nearby_place.dart';
import 'package:discover/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NEARBY PLACE CARD
// ─────────────────────────────────────────────────────────────────────────────

class NearbyPlaceCard extends StatelessWidget {
  final NearbyPlace place;
  final Color       primaryColor;
  final double?     distanceMeters;

  const NearbyPlaceCard({
    super.key,
    required this.place,
    required this.primaryColor,
    this.distanceMeters,
  });

  String? get _distanceLabel {
    final d = distanceMeters;
    if (d == null) return null;
    if (d < 1000) return 'À ${d.round()} m';
    final km = d / 1000;
    return 'À ${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
  }

  Future<void> _openWebsite() async {
    if (place.websiteUri == null) return;
    final uri = Uri.parse(place.websiteUri!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  Future<void> _callPhone() async {
    if (place.phoneNumber == null) return;
    final uri = Uri(scheme: 'tel', path: place.phoneNumber);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openMaps() async {
    final query = Uri.encodeComponent(
        '${place.name} ${place.address}');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String? get _faviconUrl {
    if (place.websiteUri == null) return null;
    try {
      final host = Uri.parse(place.websiteUri!).host;
      return 'https://www.google.com/s2/favicons?domain=$host&sz=64';
    } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final light   = Color.lerp(primaryColor, Colors.white, 0.88)!;
    final favicon = _faviconUrl;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:       Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color:     Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset:    const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Ligne 1 : nom + badge ouvert/fermé ──────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Favicon ou icône lieu
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color:        light,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: favicon != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.network(
                            favicon,
                            width: 36, height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                                Icons.place_rounded, color: primaryColor, size: 18),
                          ),
                        )
                      : Icon(Icons.place_rounded, color: primaryColor, size: 18),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        place.address,
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge ouvert / fermé
                if (place.openNow != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: place.openNow!
                          ? const Color(0xFFE8F5E9)
                          : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      place.openNow! ? 'Ouvert' : 'Fermé',
                      style: GoogleFonts.firaSansCondensed(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: place.openNow!
                            ? const Color(0xFF2E7D32)
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // ── Ligne 2 : distance + note ────────────────────────────────────
            if (_distanceLabel != null || place.rating != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                if (_distanceLabel != null) ...[
                  Icon(Icons.near_me_rounded, size: 12, color: primaryColor),
                  const SizedBox(width: 3),
                  Text(_distanceLabel!,
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryColor)),
                  const SizedBox(width: 12),
                ],
                if (place.rating != null) ...[
                  const Icon(Icons.star_rounded,
                      size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 3),
                  Text(
                    place.rating!.toStringAsFixed(1),
                    style: GoogleFonts.firaSansCondensed(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ]),
            ],

            // ── Ligne 3 : boutons actions ────────────────────────────────────
            const SizedBox(height: 12),
            Row(children: [
              // Itinéraire (texte + icône)
              Expanded(
                child: _ActionButton(
                  icon:  Icons.directions_rounded,
                  label: 'Itinéraire',
                  color: primaryColor,
                  light: light,
                  onTap: _openMaps,
                ),
              ),
              // Site web (icône seule)
              if (place.websiteUri != null) ...[
                const SizedBox(width: 8),
                _IconButton(
                  icon:  Icons.language_rounded,
                  color: primaryColor,
                  light: light,
                  onTap: _openWebsite,
                ),
              ],
              // Téléphone (icône seule)
              if (place.phoneNumber != null) ...[
                const SizedBox(width: 8),
                _IconButton(
                  icon:  Icons.phone_rounded,
                  color: primaryColor,
                  light: light,
                  onTap: _callPhone,
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Bouton icône seul ────────────────────────────────────────────────────────

class _IconButton extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final Color        light;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.color,
    required this.light,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: light,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}

// ── Bouton action avec texte ─────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData      icon;
  final String        label;
  final Color         color;
  final Color         light;
  final VoidCallback  onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.light,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color:        light,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.firaSansCondensed(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
