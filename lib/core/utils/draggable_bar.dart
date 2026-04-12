import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/theme/app_theme.dart';

// ─── DATA ─────────────────────────────────────────────────────────────────────

class TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ─── DRAGGABLE BAR ────────────────────────────────────────────────────────────

class DraggableBar extends StatefulWidget {
  final int currentTab;
  final List<TabItem> tabs;
  final ValueChanged<int> onTabChanged;

  const DraggableBar({
    super.key,
    required this.currentTab,
    required this.tabs,
    required this.onTabChanged,
  });

  @override
  State<DraggableBar> createState() => _DraggableBarState();
}

class _DraggableBarState extends State<DraggableBar>
    with SingleTickerProviderStateMixin {
  // Position normalisée de la pill [0 .. tabCount-1], peut être fractionnaire
  late double _pillPosition;
  // Pill "snappée" = onglet actif courant
  late double _snappedPosition;

  bool _isDragging = false;

  // Spring animation pour le snap au release
  late AnimationController _springCtrl;
  late Animation<double> _springAnim;

  // Largeur de la barre mesurée via LayoutBuilder
  double _barWidth = 0;

  @override
  void initState() {
    super.initState();
    _pillPosition    = widget.currentTab.toDouble();
    _snappedPosition = _pillPosition;

    _springCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _springAnim = _springCtrl.drive(
      Tween<double>(begin: 0, end: 0),
    );
    _springCtrl.addListener(() {
      setState(() => _pillPosition = _springAnim.value);
    });
  }

  @override
  void didUpdateWidget(DraggableBar old) {
    super.didUpdateWidget(old);
    // Tab changé via un tap externe → animer la pill vers la nouvelle position
    if (old.currentTab != widget.currentTab && !_isDragging) {
      _animateTo(widget.currentTab.toDouble());
    }
  }

  @override
  void dispose() {
    _springCtrl.dispose();
    super.dispose();
  }

  // Anime la pill vers une position cible avec une courbe ressort
  void _animateTo(double target) {
    _springCtrl.stop();
    _springAnim = Tween<double>(
      begin: _pillPosition,
      end: target,
    ).animate(CurvedAnimation(
      parent: _springCtrl,
      curve: Curves.elasticOut,
    ));
    _springCtrl.forward(from: 0);
  }

  // Convertit une position X en pixels en index normalisé
  double _xToPosition(double x) {
    if (_barWidth == 0) return 0;
    final tabWidth = _barWidth / widget.tabs.length;
    return (x / tabWidth).clamp(0.0, widget.tabs.length - 1.0);
  }

  // Onglet le plus proche de la position courante de la pill
  int _nearestTab(double pos) =>
      pos.round().clamp(0, widget.tabs.length - 1);

  void _onDragStart(DragStartDetails d) {
    _springCtrl.stop();
    _isDragging = true;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_barWidth == 0) return;
    final tabWidth = _barWidth / widget.tabs.length;
    final newPos = (_pillPosition + d.delta.dx / tabWidth)
        .clamp(0.0, widget.tabs.length - 1.0);

    setState(() => _pillPosition = newPos);

    // Changer d'onglet en temps réel dès qu'on croise un seuil
    final nearest = _nearestTab(newPos);
    if (nearest != widget.currentTab) {
      widget.onTabChanged(nearest);
    }
  }

  void _onDragEnd(DragEndDetails d) {
    _isDragging = false;
    final target = _nearestTab(_pillPosition).toDouble();
    _snappedPosition = target;
    _animateTo(target);
    widget.onTabChanged(_nearestTab(_pillPosition));
  }

  void _onTap(int index) {
    if (index == widget.currentTab) return;
    widget.onTabChanged(index);
    _animateTo(index.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_barWidth != constraints.maxWidth) {
              setState(() => _barWidth = constraints.maxWidth);
            }
          });

          final tabCount = widget.tabs.length;
          final tabWidth = constraints.maxWidth / tabCount;
          final pillW    = tabWidth - 12;
          final pillLeft = _pillPosition * tabWidth + 6;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            // Container extérieur : porte uniquement l'ombre
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.50),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                  // Container intérieur : fond vert semi-transparent
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1.0,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // ── Pill crème animée ──────────────────────────
                        Positioned(
                          left: pillLeft,
                          top: 6,
                          bottom: 6,
                          width: pillW,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.cream,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Icônes + labels ────────────────────────────
                        Row(
                          children: List.generate(tabCount, (i) {
                            final isActive  = i == widget.currentTab;
                            final proximity = (1 - (_pillPosition - i).abs())
                                .clamp(0.0, 1.0);

                            final iconColor = isActive
                                ? primary
                                : Color.lerp(
                              Colors.white.withValues(alpha: 0.60),
                              primary,
                              proximity * 0.35,
                            )!;

                            final labelColor = isActive
                                ? primary
                                : Colors.white.withValues(alpha: 0.60);

                            return Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _onTap(i),
                                child: SizedBox(
                                  height: 72,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 180),
                                        transitionBuilder: (child, anim) =>
                                            ScaleTransition(scale: anim, child: child),
                                        child: Icon(
                                          isActive
                                              ? widget.tabs[i].activeIcon
                                              : widget.tabs[i].icon,
                                          key: ValueKey(isActive),
                                          size: 22,
                                          color: iconColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 200),
                                        style: GoogleFonts.firaSansCondensed(
                                          fontSize: 10,
                                          fontWeight: isActive
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: labelColor,
                                          letterSpacing: isActive ? 0.3 : 0,
                                        ),
                                        child: Text(widget.tabs[i].label),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
