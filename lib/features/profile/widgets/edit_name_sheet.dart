import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

class EditNameSheet extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSave;

  const EditNameSheet({
    super.key,
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: ClipRRect(
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
            Text('Modifier le nom',
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 16, color: AppColors.ink),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: InputBorder.none,
                  hintText: 'Ton prénom ou pseudo',
                  hintStyle: GoogleFonts.firaSansCondensed(
                      color: AppColors.inkSoft),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final primary = Theme.of(context).colorScheme.primary;
              return GestureDetector(
              onTap: () => onSave(controller.text.trim().isNotEmpty
                  ? controller.text.trim()
                  : 'Toi'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text('Enregistrer',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            );
            }),
          ]),
        ),
      ),
    );
  }
}
