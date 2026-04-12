import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

class ContinueButton extends StatefulWidget {
  final String        label;
  final bool          enabled;
  final VoidCallback? onTap;

  const ContinueButton({
    super.key,
    required this.label,
    required this.enabled,
    this.onTap,
  });

  @override
  State<ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<ContinueButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _ctrl.forward() : null,
      onTapUp: widget.enabled ? (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      } : null,
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: widget.enabled ? primary : primary.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.anton(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.enabled
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
