import 'package:discover/core/utils/draggable_bar.dart';
import 'package:discover/features/explorer/explorer.dart';
import 'package:discover/features/home/home.dart';
import 'package:discover/features/map/map.dart';
import 'package:discover/features/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:discover/core/theme/app_theme.dart';

class MainShell extends StatefulWidget {
  final bool isGuest;
  const MainShell({super.key, this.isGuest = false});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _currentTab = 0;

  /// Clés de rebuild pour carte et profil (reconstruits à chaque visite).
  final List<int> _tabKeys = [0, 0, 0, 0];

  /// Clés d'animation séparées — changent au tap BottomBar uniquement.
  /// Explorer et Home gardent leurs données mais rejouent les animations.
  int _homeAnimKey     = 0;
  int _explorerAnimKey = 0;

  /// Vrai quand l'app est en arrière-plan — empêche le replay d'animations
  /// sur un simple retour en foreground.
  bool _appInBackground = false;

  late AnimationController _tabCtrl;

  final List<TabItem> _tabs = const [
    TabItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: 'Discover',
    ),
    TabItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Explorer',
    ),
    TabItem(
      icon: Icons.public_outlined,
      activeIcon: Icons.public_rounded,
      label: 'Carte',
    ),
    TabItem(
      icon: Icons.person_outlined,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── AppLifecycle : ne pas rejouer les animations au retour en foreground ──
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _appInBackground = true;
    } else if (state == AppLifecycleState.resumed) {
      // On remet le flag à false après un tick pour ne pas bloquer
      // le prochain tap BottomBar réel.
      Future.microtask(() => _appInBackground = false);
    }
  }

  void _onTabChanged(int index) {
    if (index == _currentTab) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentTab = index;
      // Pas d'animation au retour depuis le background
      if (_appInBackground) return;

      if (index == 0) {
        // Home : données préservées, animations rejouées
        _homeAnimKey++;
      } else if (index == 1) {
        // Explorer : données préservées, animations rejouées
        _explorerAnimKey++;
      } else {
        // Carte & Profil : rebuild complet
        _tabKeys[index]++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // ── Écrans ────────────────────────────────────────────────────────
          for (int i = 0; i < 4; i++)
            Offstage(
              offstage: _currentTab != i,
              child: TickerMode(
                enabled: _currentTab == i,
                child: switch (i) {
                  0 => HomeScreen(animKey: _homeAnimKey),
                  1 => ExplorerScreen(animKey: _explorerAnimKey),
                  _ => KeyedSubtree(
                      key: ValueKey(_tabKeys[i]),
                      child: i == 2 ? const MapScreen() : ProfileScreen(isGuest: widget.isGuest),
                    ),
                },
              ),
            ),

          // ── Barre flottante draggable ──────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DraggableBar(
              currentTab: _currentTab,
              tabs:       _tabs,
              onTabChanged: _onTabChanged,
            ),
          ),
        ],
      ),
    );
  }
}
