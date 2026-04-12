import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:discover/core/services/community_service.dart';
import 'package:discover/features/home/widgets/community_models.dart';
import 'package:discover/core/theme/app_theme.dart';

class EditPostSheet extends StatefulWidget {
  final CommunityPost post;

  const EditPostSheet({super.key, required this.post});

  @override
  State<EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<EditPostSheet> {
  late final TextEditingController _captionCtrl;
  File?  _newImage;
  bool   _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _captionCtrl = TextEditingController(text: widget.post.caption);
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    final xfile = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (xfile != null) setState(() => _newImage = File(xfile.path));
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      await CommunityService.updatePost(
        postId:       widget.post.id,
        passionId:    widget.post.passionId,
        caption:      _captionCtrl.text.trim(),
        newImageFile: _newImage,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = 'Erreur. Réessaie.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq         = MediaQuery.of(context);
    final keyboardH  = mq.viewInsets.bottom;
    final safeBottom = mq.padding.bottom;

    final primary = Theme.of(context).colorScheme.primary;
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardH),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          color: AppColors.cream,
          padding: EdgeInsets.fromLTRB(20, 16, 20, safeBottom + 20),
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
            const SizedBox(height: 16),

            // Titre + bouton Enregistrer
            Row(children: [
              Expanded(
                child: Text('Modifier la publication',
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
              ),
              GestureDetector(
                onTap: _saving ? null : _save,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: _saving
                        ? primary.withValues(alpha: 0.5)
                        : primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Enregistrer',
                          style: GoogleFonts.firaSansCondensed(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Aperçu image + bouton changer
            GestureDetector(
              onTap: _pickImage,
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: _newImage != null
                        ? Image.file(_newImage!, fit: BoxFit.cover)
                        : CachedNetworkImage(
                            imageUrl: widget.post.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: AppColors.greenLight),
                            errorWidget: (_, __, ___) =>
                                Container(color: AppColors.greenLight),
                          ),
                  ),
                ),
                // Overlay "Changer"
                Positioned(
                  right: 10, bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.photo_library_outlined,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                      Text('Changer',
                          style: GoogleFonts.firaSansCondensed(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),

            // Champ description
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08)),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: TextField(
                controller: _captionCtrl,
                maxLines: 3,
                minLines: 2,
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 14, color: AppColors.ink),
                decoration: InputDecoration.collapsed(
                  hintText: 'Description…',
                  hintStyle: GoogleFonts.firaSansCondensed(
                      fontSize: 14, color: AppColors.inkSoft),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: GoogleFonts.firaSansCondensed(
                      fontSize: 12, color: AppColors.error)),
            ],
          ]),
        ),
      ),
    );
  }
}
