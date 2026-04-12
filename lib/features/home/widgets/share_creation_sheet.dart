import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/features/home/screens/create_post_screen.dart';
import 'package:discover/features/home/widgets/share_option.dart';
import 'package:discover/core/theme/app_theme.dart';

class ShareCreationSheet extends StatelessWidget {
  final Passion passion;
  const ShareCreationSheet({super.key, required this.passion});

  Future<void> _pick(BuildContext context, ImageSource source) async {
    HapticFeedback.lightImpact();
    final xfile = await ImagePicker().pickImage(
        source: source, imageQuality: 85, maxWidth: 1200);
    if (xfile == null) return;
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CreatePostScreen(
        passion: passion,
        image:   File(xfile.path),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: AppColors.cream,
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text('Partager une création',
              style: GoogleFonts.firaSansCondensed(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 6),
          Text(
            'Montre ta progression à la communauté ${passion.name}',
            style: GoogleFonts.firaSansCondensed(
                fontSize: 13, color: AppColors.inkSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          ShareOption(
            icon:  Icons.photo_library_outlined,
            label: 'Choisir depuis la galerie',
            onTap: () => _pick(context, ImageSource.gallery),
          ),
          const SizedBox(height: 10),
          ShareOption(
            icon:  Icons.camera_alt_outlined,
            label: 'Prendre une photo',
            onTap: () => _pick(context, ImageSource.camera),
          ),
        ]),
      ),
    );
  }
}
