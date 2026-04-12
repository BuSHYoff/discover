import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/core/theme/app_theme.dart';

class PassionCard extends StatefulWidget {
  final Passion passion;
  final VoidCallback onTap;
  final bool isLaunching;
  final Animation<double> chevronAnim;

  const PassionCard({
    super.key,
    required this.passion,
    required this.onTap,
    required this.isLaunching,
    required this.chevronAnim,
  });

  @override
  State<PassionCard> createState() => _PassionCardState();
}

class _PassionCardState extends State<PassionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  static const double _radius = 28;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  TextStyle get _heroTitleStyle => GoogleFonts.firaSansCondensed(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.15,
  );

  @override
  Widget build(BuildContext context) {
    final uiOpacity = widget.isLaunching ? 0.0 : 1.0;
    const fadeDuration = Duration(milliseconds: 160);

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Hero image ───────────────────────────────────────────────
            Hero(
              tag: 'passion-image-${widget.passion.id}',
              createRectTween: (begin, end) =>
                  MaterialRectCenterArcTween(begin: begin, end: end),
              flightShuttleBuilder: (_, __, ___, ____, _____) => ClipRRect(
                borderRadius: BorderRadius.circular(_radius),
                child: Image.network(
                  widget.passion.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.ink),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_radius),
                child: Image.network(
                  widget.passion.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const _ShimmerBox();
                  },
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.ink),
                ),
              ),
            ),

            // ── Gradient overlay ─────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(_radius),
              child: AnimatedOpacity(
                opacity: uiOpacity,
                duration: fadeDuration,
                curve: Curves.easeOut,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.35, 0.60, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.30),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.60),
                        Colors.black.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────────────
            AnimatedOpacity(
              opacity: uiOpacity,
              duration: fadeDuration,
              curve: Curves.easeOut,
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.passion.category,
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(flex: 1),

                    // ── Hero titre ───────────────────────────────────────
                    Hero(
                      tag: 'passion-title-${widget.passion.id}',
                      createRectTween: (begin, end) =>
                          MaterialRectCenterArcTween(begin: begin, end: end),
                      flightShuttleBuilder: (_, __, ___, ____, _____) =>
                          Material(
                            color: Colors.transparent,
                            child: Text(
                              widget.passion.name,
                              style: _heroTitleStyle,
                            ),
                          ),
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          widget.passion.name,
                          style: _heroTitleStyle,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text(
                      widget.passion.description,
                      style: GoogleFonts.firaSansCondensed(
                        fontSize: 13.5,
                        height: 1.6,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w300,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    // ── Hint "Glisse" toujours visible ───────────────────
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Glisse pour découvrir',
                            style: GoogleFonts.firaSansCondensed(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedBuilder(
                            animation: widget.chevronAnim,
                            builder: (_, __) => Transform.translate(
                              offset: Offset(0, widget.chevronAnim.value),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white.withValues(alpha: 0.35),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER BOX — placeholder animé pendant le chargement de l'image
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final x = -1.5 + _ctrl.value * 3.5;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(x - 1, 0),
              end: Alignment(x + 1, 0),
              colors: const [
                Color(0xFF1A1A1A),
                Color(0xFF262626),
                Color(0xFF333333),
                Color(0xFF262626),
                Color(0xFF1A1A1A),
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),
        );
      },
    );
  }
}
