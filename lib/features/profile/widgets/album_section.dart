import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/features/profile/widgets/photo_tile.dart';
import 'package:discover/core/theme/app_theme.dart';

class AlbumSection extends StatelessWidget {
  final List<String> photos;
  final VoidCallback onAdd;
  final void Function(String) onRemove;

  const AlbumSection({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.photo_library_outlined,
                  color: primary, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Album photos',
                  style: GoogleFonts.firaSansCondensed(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
            ),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('Ajouter',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ]),
              ),
            ),
          ]),

          if (photos.isEmpty) ...[
            const SizedBox(height: 20),
            Center(
              child: Column(children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 36, color: AppColors.inkSoft.withValues(alpha: 0.35)),
                const SizedBox(height: 8),
                Text('Aucune photo pour l\'instant',
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 13, color: AppColors.inkSoft)),
                const SizedBox(height: 4),
                Text('Ajoute tes meilleurs moments !',
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 11, color: AppColors.inkSoft.withValues(alpha: 0.6))),
              ]),
            ),
            const SizedBox(height: 8),
          ] else ...[
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: photos.length,
              itemBuilder: (context, i) => PhotoTile(
                path: photos[i],
                onDelete: () => onRemove(photos[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
