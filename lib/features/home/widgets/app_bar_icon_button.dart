import 'package:flutter/material.dart';
import 'package:discover/core/theme/app_theme.dart';

class AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool scrolled;

  const AppBarIconButton({super.key, required this.icon, required this.onTap, required this.scrolled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.ink, size: 18),
      ),
    );
  }
}
