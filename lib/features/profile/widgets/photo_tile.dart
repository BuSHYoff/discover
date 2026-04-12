import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:discover/features/profile/widgets/delete_photo_sheet.dart';
import 'package:discover/core/theme/app_theme.dart';

class PhotoTile extends StatelessWidget {
  final String path;
  final VoidCallback onDelete;

  const PhotoTile({super.key, required this.path, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => DeletePhotoSheet(onDelete: onDelete),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.greenLight,
            child: const Icon(Icons.broken_image_outlined,
                color: AppColors.green, size: 24),
          ),
        ),
      ),
    );
  }
}
