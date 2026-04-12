import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

class NextButton extends StatefulWidget {
  final String label;
  final bool isLast;
  final bool enabled;
  final VoidCallback onTap;

  const NextButton({
    super.key,
    required this.label,
    required this.isLast,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<NextButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled;
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTapDown: isEnabled ? (_) => _ctrl.forward() : null,
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isEnabled ? primary : primary.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(18),
            boxShadow: isEnabled ? [BoxShadow(
                color: primary.withValues(alpha: 0.3),
                blurRadius: 20, offset: const Offset(0, 8))] : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(widget.label, style: GoogleFonts.firaSansCondensed(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: Colors.white, letterSpacing: -0.2)),
            const SizedBox(width: 8),
            Icon(
              widget.isLast
                  ? Icons.check_circle_outline_rounded
                  : Icons.arrow_forward_rounded,
              color: Colors.white, size: 17,
            ),
          ]),
        ),
      ),
    );
  }
}
