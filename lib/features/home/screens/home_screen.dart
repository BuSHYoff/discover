import 'dart:math' as math;
import 'package:discover/features/home/widgets/staggered_bounce.dart';
import 'package:discover/features/home/widgets/passion_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/features/home/screens/detail_screen.dart';
import 'package:discover/features/profile/screens/profile_screen.dart';
import 'package:discover/core/theme/app_theme.dart';
import 'package:discover/core/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  /// Incrémenté par MainShell à chaque retour sur l'onglet.
  /// Rejoue les StaggeredBounce sans recharger les données.
  final int animKey;

  const HomeScreen({super.key, this.animKey = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  String? _launchingPassionId;

  // Bounce du chevron "glisse pour découvrir"
  late AnimationController _chevronCtrl;
  late Animation<double> _chevronAnim;

  // Bounce de la carte (géré manuellement pour ne jamais remounter le PageView)
  late AnimationController _cardBounceCtrl;
  late Animation<Offset> _cardOffset;
  late Animation<double> _cardOpacity;

  // Liste de toutes les passions mélangées aléatoirement pour le scroll infini
  late final List<Passion> _shuffledPassions;

  List<Passion> get _discoverPassions => _shuffledPassions;

  @override
  void initState() {
    super.initState();
    // Mélange aléatoire de toutes les passions
    _shuffledPassions = List.of(allPassions)..shuffle(math.Random());
    _pageController = PageController();

    // ── Chevron ──────────────────────────────────────────────────────────────
    _chevronCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _chevronAnim = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _chevronCtrl, curve: Curves.easeInOut));

    // ── Card bounce ──────────────────────────────────────────────────────────
    _cardBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _cardOffset = Tween<Offset>(
      begin: const Offset(0, 0.40),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardBounceCtrl,
      curve: const _BallBounceCurve(),
    ));
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardBounceCtrl,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
      ),
    );

    // Délai calé sur index 2 de la cascade (60ms init + 2×65ms stagger)
    Future.delayed(const Duration(milliseconds: 190), () {
      if (mounted) _cardBounceCtrl.forward();
    });

    // Demande la permission notifs à la première ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationPermission();
    });
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // animKey change → rejouer le bounce de la carte SANS remounter le PageView
    if (widget.animKey != oldWidget.animKey) {
      _cardBounceCtrl.reset();
      Future.delayed(const Duration(milliseconds: 190), () {
        if (mounted) _cardBounceCtrl.forward();
      });
    }
  }

  Future<void> _checkNotificationPermission() async {
    final neverAsked = await NotificationService.hasNeverAskedPermission();
    if (!neverAsked) {
      await NotificationService.initFcmToken();
      return;
    }
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await NotificationService.initFcmToken();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chevronCtrl.dispose();
    _cardBounceCtrl.dispose();
    super.dispose();
  }

  Future<void> _openDetail(Passion passion) async {
    ProfileData.instance.markViewed(passion.id);

    setState(() => _launchingPassionId = passion.id);
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => DetailScreen(passion: passion, useHero: true),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 480),
        reverseTransitionDuration: const Duration(milliseconds: 480),
      ),
    );

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _launchingPassionId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header : rekeyed → animations header rejouées
            KeyedSubtree(
              key: ValueKey('home_header_${widget.animKey}'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StaggeredBounceEntry(
                      index: 0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: GoogleFonts.firaSansCondensed(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink,
                                  height: 1.05,
                                ),
                                children: [
                                  const TextSpan(text: 'Discover'),
                                  TextSpan(text: '.', style: TextStyle(color: primary)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    StaggeredBounceEntry(
                      index: 1,
                      child: Text(
                        'Trouve les passions qui te correspondent !',
                        style: GoogleFonts.firaSansCondensed(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.inkSoft,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // ── PageView : JAMAIS remonté → position toujours préservée.
            //    Le bounce est piloté par _cardBounceCtrl via didUpdateWidget.
            Expanded(
              child: AnimatedBuilder(
                animation: _cardBounceCtrl,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (context, index) {
                      final passion =
                          _discoverPassions[index % _discoverPassions.length];
                      final isLaunching = _launchingPassionId == passion.id;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 112,
                        ),
                        child: PassionCard(
                          passion: passion,
                          isLaunching: isLaunching,
                          onTap: () => _openDetail(passion),
                          chevronAnim: _chevronAnim,
                        ),
                      );
                    },
                  ),
                ),
                builder: (context, child) => FractionalTranslation(
                  translation: _cardOffset.value,
                  child: Opacity(
                    opacity: _cardOpacity.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Même courbe que StaggeredBounceEntry — chute cubique + 2 rebonds
class _BallBounceCurve extends Curve {
  const _BallBounceCurve();

  @override
  double transformInternal(double t) {
    if (t < 0.52) {
      final p = t / 0.52;
      return p * p * p;
    }
    if (t < 0.72) {
      final p = (t - 0.52) / 0.20;
      return 1.0 + 0.09 * math.sin(p * math.pi);
    }
    if (t < 0.88) {
      final p = (t - 0.72) / 0.16;
      return 1.0 + 0.03 * math.sin(p * math.pi);
    }
    final p = (t - 0.88) / 0.12;
    return 1.0 + 0.008 * math.sin(p * math.pi);
  }
}
