import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/core/services/community_service.dart';
import 'package:discover/core/theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  final Passion passion;

  const CreatePostScreen({super.key, required this.passion});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleCtrl   = TextEditingController();
  final _captionCtrl = TextEditingController();
  File?  _image;
  bool   _publishing = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.lightImpact();
    final xfile = await ImagePicker().pickImage(
      source:       source,
      imageQuality: 85,
      maxWidth:     1200,
    );
    if (xfile == null) return;
    setState(() => _image = File(xfile.path));
  }

  void _showImagePicker() {
    final primary       = Theme.of(context).colorScheme.primary;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          color: AppColors.cream,
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 20),
            _PickerOption(
              icon:  Icons.photo_library_outlined,
              label: 'Choisir depuis la galerie',
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              primary: primary,
            ),
            const SizedBox(height: 10),
            _PickerOption(
              icon:  Icons.camera_alt_outlined,
              label: 'Prendre une photo',
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              primary: primary,
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _publish() async {
    if (_image == null) {
      setState(() => _error = 'Ajoute une image à ta publication.');
      return;
    }
    HapticFeedback.lightImpact();
    setState(() { _publishing = true; _error = null; });
    try {
      await CommunityService.addPost(
        passionId: widget.passion.id,
        imageFile: _image!,
        title:     _titleCtrl.text.trim(),
        caption:   _captionCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
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
    final primary       = Theme.of(context).colorScheme.primary;
    final topPadding    = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(children: [

        // ── App bar ────────────────────────────────────────────────────────
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Nouvelle publication',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink)),
                  Text('Partage tes envies avec la communauté',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 12, color: AppColors.inkSoft)),
                ],
              ),
            ),
          ]),
        ),

        // ── Contenu scrollable ─────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Titre ────────────────────────────────────────────────
                _FieldLabel(label: 'Titre'),
                const SizedBox(height: 6),
                _StyledField(
                  controller: _titleCtrl,
                  hint:     'Donne un titre à ta publication…',
                  minLines: 1,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // ── Description ──────────────────────────────────────────
                _FieldLabel(label: 'Description'),
                const SizedBox(height: 6),
                _StyledField(
                  controller: _captionCtrl,
                  hint:     'Décris ta création, partage tes astuces…',
                  minLines: 4,
                  maxLines: null,
                ),

                const SizedBox(height: 20),

                // ── Zone image ───────────────────────────────────────────
                GestureDetector(
                  onTap: _showImagePicker,
                  child: Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: _image == null
                          ? primary.withValues(alpha: 0.06)
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _image == null
                            ? primary.withValues(alpha: 0.2)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: _image == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                              Icons.add_photo_alternate_outlined,
                              color: primary, size: 26),
                        ),
                        const SizedBox(height: 12),
                        Text('Ajouter une photo',
                            style: GoogleFonts.firaSansCondensed(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: primary)),
                        const SizedBox(height: 4),
                        Text('Galerie ou appareil photo',
                            style: GoogleFonts.firaSansCondensed(
                                fontSize: 12,
                                color: AppColors.inkSoft)),
                      ],
                    )
                        : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_image!, fit: BoxFit.cover),
                        Positioned(
                          bottom: 8, right: 8,
                          child: GestureDetector(
                            onTap: _showImagePicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.edit_outlined,
                                        size: 13,
                                        color: Colors.white),
                                    const SizedBox(width: 5),
                                    Text('Changer',
                                        style: GoogleFonts
                                            .firaSansCondensed(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        )),
                                  ]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Erreur ───────────────────────────────────────────────
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 12, color: AppColors.error)),
                ],
              ],
            ),
          ),
        ),

        // ── Bouton publier fixe en bas ─────────────────────────────────────
        Container(
          color: AppColors.cream,
          padding:
              EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 16),
          child: GestureDetector(
            onTap: _publishing ? null : _publish,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _publishing
                    ? primary.withValues(alpha: 0.5)
                    : primary,
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

// ── Widgets helpers ───────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: GoogleFonts.firaSansCondensed(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.inkSoft,
          letterSpacing: 0.6,
        ),
      );
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int    minLines;
  final int?   maxLines;

  const _StyledField({
    required this.controller,
    required this.hint,
    required this.minLines,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: TextField(
        controller:          controller,
        minLines:            minLines,
        maxLines:            maxLines,
        textCapitalization:  TextCapitalization.sentences,
        style: GoogleFonts.firaSansCondensed(
            fontSize: 15, color: AppColors.ink, height: 1.5),
        decoration: InputDecoration.collapsed(
          hintText: hint,
          hintStyle: GoogleFonts.firaSansCondensed(
              fontSize: 15,
              color: AppColors.inkSoft.withValues(alpha: 0.55),
              height: 1.5),
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback onTap;
  final Color    primary;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.black.withValues(alpha: 0.07)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: primary),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.firaSansCondensed(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink)),
        ]),
      ),
    );
  }
}
