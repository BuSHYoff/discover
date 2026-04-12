import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/core/services/community_service.dart';
import 'package:discover/core/theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  final Passion passion;
  final File    image;

  const CreatePostScreen({
    super.key,
    required this.passion,
    required this.image,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionCtrl  = TextEditingController();
  final _captionFocus = FocusNode();
  bool  _publishing   = false;
  String? _error;

  @override
  void dispose() {
    _captionCtrl.dispose();
    _captionFocus.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    HapticFeedback.lightImpact();
    setState(() { _publishing = true; _error = null; });
    try {
      await CommunityService.addPost(
        passionId: widget.passion.id,
        imageFile: widget.image,
        caption:   _captionCtrl.text.trim(),
      );
      if (mounted) {
        // Ferme la page ET la sheet en dessous
        Navigator.of(context)
          ..pop()  // ferme CreatePostScreen
          ..pop(); // ferme ShareCreationSheet
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _publishing = false;
          _error = 'Erreur lors de la publication. Réessaie.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding    = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(children: [

        // ── App bar ───────────────────────────────────────────────────────────
        Container(
          color: AppColors.cream,
          padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 12),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.black.withValues(alpha: 0.08)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppColors.ink),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Nouvelle publication',
                  style: GoogleFonts.firaSansCondensed(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
            ),
          ]),
        ),

        // ── Contenu scrollable ────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(bottom: bottomPadding + 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Image
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.file(widget.image, fit: BoxFit.cover),
                ),

                const SizedBox(height: 20),

                // Label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Description',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,
                          letterSpacing: 0.5)),
                ),
                const SizedBox(height: 8),

                // Champ description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.08)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: TextField(
                      controller:  _captionCtrl,
                      focusNode:   _captionFocus,
                      maxLines:    null,
                      minLines:    4,
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 15, color: AppColors.ink, height: 1.5),
                      decoration: InputDecoration.collapsed(
                        hintText:
                            'Décris ta création, partage tes astuces…',
                        hintStyle: GoogleFonts.firaSansCondensed(
                            fontSize: 15,
                            color: AppColors.inkSoft.withValues(alpha: 0.6),
                            height: 1.5),
                      ),
                    ),
                  ),
                ),

                // Erreur
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: Text(_error!,
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 12, color: AppColors.error)),
                  ),
              ],
            ),
          ),
        ),

        // ── Bouton publier fixe en bas ─────────────────────────────────────────
        Container(
          color: AppColors.cream,
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 16),
          child: GestureDetector(
            onTap: _publishing ? null : _publish,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _publishing
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: _publishing
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text('Publier',
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
