import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

class DeletePhotoSheet extends StatelessWidget {
  final VoidCallback onDelete;

  const DeletePhotoSheet({super.key, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        color: AppColors.cream,
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              onDelete();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFFFCCCC)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFCC3333), size: 18),
                  const SizedBox(width: 8),
                  Text('Supprimer la photo',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFCC3333))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.black.withValues(alpha: 0.07)),
              ),
              child: Center(
                child: Text('Annuler',
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
