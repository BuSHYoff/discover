import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';
import 'package:discover/features/profile/screens/profile_screen.dart';

class CTAButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isResume;
  final bool isDone;

  const CTAButton({super.key, required this.onTap, this.isResume = false, this.isDone = false});

  @override
  State<CTAButton> createState() => _CTAButtonState();
}

class _CTAButtonState extends State<CTAButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDone) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
        ),
        child: Row(children: [
          Container(width: 42, height: 42,
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(13)),
              child: Icon(Icons.check_circle_outline_rounded, color: AppColors.inkSoft.withValues(alpha: 0.5), size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Activité terminée', style: GoogleFonts.firaSansCondensed(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
            const SizedBox(height: 2),
            Text('Tu as complété cette passion', style: GoogleFonts.firaSansCondensed(fontSize: 11.5, color: AppColors.inkSoft.withValues(alpha: 0.7))),
          ])),
          Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.inkSoft.withValues(alpha: 0.35)),
        ]),
      );
    }

    final pt = ProfileTheme.fromHex(ProfileData.instance.profileColorHex);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap?.call(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [pt.primary, pt.dark],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: pt.shadow(0.30), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Row(children: [
            Container(width: 42, height: 42,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(13)),
                child: Icon(widget.isResume ? Icons.play_circle_outline_rounded : Icons.rocket_launch_rounded, color: Colors.white, size: 20)),
            const SizedBox(width: 14),
            Expanded(child: Text(
                widget.isResume ? 'Reprendre l\'activité en cours' : 'Commencer l\'activité',
                style: GoogleFonts.firaSansCondensed(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.white.withValues(alpha: 0.6)),
          ]),
        ),
      ),
    );
  }
}
