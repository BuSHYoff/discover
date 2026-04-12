import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import 'package:discover/features/map/screens/map_screen.dart';
import 'package:discover/features/home/widgets/detail_models.dart';
import 'package:discover/core/theme/app_theme.dart';

class OriginBubble extends StatefulWidget {
  final String country;
  final String passionId;
  const OriginBubble({super.key, required this.country, required this.passionId});

  @override
  State<OriginBubble> createState() => _OriginBubbleState();
}

class _OriginBubbleState extends State<OriginBubble>
    with SingleTickerProviderStateMixin {
  static const double _size = 70.0;

  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openMap() {
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => MapScreen(highlightCountry: widget.country, excludePassionId: widget.passionId),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final focus = focusFor(widget.country);
    const double mapNativeW = 1000.0;
    const double mapNativeH = 507.0;
    final double renderScale = _size / mapNativeW;
    final double tx = _size / 2 - focus.dx * mapNativeW * renderScale * focus.zoom;
    final double ty = _size / 2 - focus.dy * mapNativeH * renderScale * focus.zoom;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) { HapticFeedback.lightImpact(); _ctrl.forward(); },
      onTapUp: (_) { _ctrl.reverse(); _openMap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Stack(children: [
              Transform.translate(
                offset: Offset(tx, ty),
                child: Transform.scale(
                  scale: focus.zoom,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: mapNativeW * renderScale,
                    height: mapNativeH * renderScale,
                    child: IgnorePointer(
                      child: SimpleMap(
                        instructions: SMapWorld.instructions,
                        defaultColor: AppColors.greyLight,
                        colors: {widget.country.toLowerCase(): primary},
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
