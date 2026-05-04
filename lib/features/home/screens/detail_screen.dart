import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/features/journey/screens/journey_screen.dart';
import 'package:discover/features/journey/widgets/journey_progress.dart';
import 'package:discover/features/home/screens/community_screen.dart';
import 'package:discover/features/profile/screens/profile_screen.dart';
import 'package:discover/features/home/widgets/hero_icon_button.dart';
import 'package:discover/features/home/widgets/app_bar_icon_button.dart';
import 'package:discover/features/home/widgets/tips_page.dart';
import 'package:discover/features/home/widgets/resources_page.dart';
import 'package:discover/features/home/widgets/notifications_sheet.dart';
import 'package:discover/features/home/widgets/drop_cap_text.dart';
import 'package:discover/features/home/widgets/progress_card.dart';
import 'package:discover/features/home/widgets/progress_sheet.dart';
import 'package:discover/features/home/widgets/origin_bubble.dart';
import 'package:discover/features/home/widgets/cta_button.dart';
import 'package:discover/core/theme/app_theme.dart';
import 'package:discover/core/services/notification_service.dart';
import 'package:discover/features/nearby/screens/nearby_screen.dart';

// ─── PROVIDER DU CONTENU IA ───────────────────────────────────────────────────

class AIContentProvider {
  static Future<AIContent?> getFor(String passionId) async {
    return PassionRepository.instance.aiCache[passionId];
  }
}

// ─── DETAIL SCREEN ────────────────────────────────────────────────────────────

class DetailScreen extends StatefulWidget {
  final Passion passion;
  /// Active l'animation Hero (uniquement depuis la home screen).
  final bool useHero;
  const DetailScreen({super.key, required this.passion, this.useHero = false});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _gradientCtrl;
  late Animation<double> _gradientAnim;
  late AnimationController _chevronCtrl;
  late Animation<double> _chevronAnim;

  final ScrollController _scrollCtrl = ScrollController();
  bool _showAppBarTitle = false;
  bool _reminderEnabled = false;

  late final JourneyProgress _progress;

  static const double _cardRadius = 28;

  Passion get passion => widget.passion;
  bool   get _useHero => widget.useHero;

  // ── Helpers Hero conditionnels ────────────────────────────────────────────

  Widget _maybeHeroImage(Passion p) {
    final image = Image.network(
      p.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: AppColors.cream),
    );
    if (!_useHero) return image;
    return Hero(
      tag: 'passion-image-${p.id}',
      createRectTween: (begin, end) =>
          MaterialRectCenterArcTween(begin: begin, end: end),
      flightShuttleBuilder: (_, animation, __, ___, ____) {
        final radiusTween = BorderRadiusTween(
          begin: const BorderRadius.all(Radius.circular(_cardRadius)),
          end: BorderRadius.zero,
        );
        return AnimatedBuilder(
          animation: animation,
          builder: (_, __) => ClipRRect(
            borderRadius: radiusTween.evaluate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            )!,
            child: image,
          ),
        );
      },
      child: image,
    );
  }

  Widget _maybeHeroTitle(Passion p) {
    final text = Material(
      color: Colors.transparent,
      child: Text(
        p.name,
        style: GoogleFonts.firaSansCondensed(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.15,
        ),
      ),
    );
    if (!_useHero) return text;
    return Hero(
      tag: 'passion-title-${p.id}',
      createRectTween: (begin, end) =>
          MaterialRectCenterArcTween(begin: begin, end: end),
      flightShuttleBuilder: (_, __, ___, ____, _____) => text,
      child: text,
    );
  }

  @override
  void initState() {
    super.initState();

    _progress = JourneyProgress.of(passion.id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ProfileData.instance.markViewed(passion.id);
    });

    // Charger l'état réel du rappel
    NotificationService.isReminderEnabled(passion.id).then((enabled) {
      if (mounted) setState(() => _reminderEnabled = enabled);
    });

    _gradientCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
        reverseDuration: const Duration(milliseconds: 180));
    _gradientAnim =
        CurvedAnimation(parent: _gradientCtrl, curve: Curves.easeIn);
    Future.delayed(const Duration(milliseconds: 420), () {
      if (mounted) _gradientCtrl.forward();
    });
    _chevronCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _chevronAnim = Tween<double>(begin: 0.0, end: 8.0).animate(
        CurvedAnimation(parent: _chevronCtrl, curve: Curves.easeInOut));
    _scrollCtrl.addListener(() {
      final show = _scrollCtrl.offset > 220;
      if (show != _showAppBarTitle) setState(() => _showAppBarTitle = show);
    });
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    _chevronCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _share() {
    HapticFeedback.lightImpact();
    SharePlus.instance.share(ShareParams(
      text: 'Découvre ${passion.name} sur Discover !',
      subject: 'Découvre ${passion.name}',
    ));
  }

  void _openJourney() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => JourneyScreen(passion: passion, progress: _progress),
    ));
  }

  void _showProgressPopup() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ProgressSheet(progress: _progress, passion: passion),
    );
  }

  void _openSecrets() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TipsPage(passion: passion),
    ));
  }

  void _showNotificationsModal() async {
    HapticFeedback.lightImpact();

    // Vérifier la permission d'abord
    final granted = await NotificationService.isPermissionGranted();
    if (!mounted) return;

    if (!granted) {
      // Montrer d'abord la sheet, et si l'user active → demander la permission
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NotificationsSheet(
        enabled: _reminderEnabled,
        onChanged: (enable) async {
          Navigator.of(context).pop();
          if (enable) {
            // Vérifier/demander la permission
            bool ok = await NotificationService.isPermissionGranted();
            if (!ok) {
              ok = await NotificationService.requestPermission();
            }
            if (ok) {
              await NotificationService.scheduleWeeklyReminder(
                passionId: passion.id,
                passionName: passion.name,
              );
              if (mounted) setState(() => _reminderEnabled = true);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Active les notifications dans les réglages pour recevoir des rappels.',
                      style: GoogleFonts.firaSansCondensed(fontSize: 13),
                    ),
                    backgroundColor: AppColors.ink,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            }
          } else {
            await NotificationService.cancelReminder(passion.id);
            if (mounted) setState(() => _reminderEnabled = false);
          }
        },
      ),
    );
  }

  void _openRessources() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResourcesPage(passion: passion),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        controller: _scrollCtrl,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.cream,
            automaticallyImplyLeading: false,
            title: AnimatedOpacity(
              opacity: _showAppBarTitle ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Row(
                children: [
                  Expanded(
                    child: Text(passion.name,
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                  ),
                  AppBarIconButton(
                    icon: Icons.menu_book_outlined,
                    onTap: _openRessources,
                    scrolled: _showAppBarTitle,
                  ),
                  const SizedBox(width: 8),
                  AppBarIconButton(
                    icon: Icons.lightbulb_outline_rounded,
                    onTap: _openSecrets,
                    scrolled: _showAppBarTitle,
                  ),
                ],
              ),
            ),
            leading: GestureDetector(
              onTap: () async {
                await _gradientCtrl.reverse();
                if (mounted) Navigator.of(context).pop();
              },
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _showAppBarTitle
                            ? Colors.black.withValues(alpha: 0.06)
                            : Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: _showAppBarTitle ? null : Border.all(
                            color: Colors.white.withValues(alpha: 0.25), width: 1),
                      ),
                      child: Icon(Icons.arrow_back,
                          color: _showAppBarTitle ? AppColors.ink : Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: _showNotificationsModal,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: _showAppBarTitle
                                ? (_reminderEnabled
                                ? primaryLight
                                : Colors.black.withValues(alpha: 0.06))
                                : Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: _showAppBarTitle
                                ? (_reminderEnabled
                                ? Border.all(color: primary.withValues(alpha: 0.3))
                                : null)
                                : Border.all(
                                color: Colors.white.withValues(alpha: 0.25), width: 1),
                          ),
                          child: Icon(
                            _reminderEnabled
                                ? Icons.notifications_rounded
                                : Icons.notifications_outlined,
                            color: _showAppBarTitle
                                ? (_reminderEnabled ? primary : AppColors.ink)
                                : Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: _share,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: _showAppBarTitle
                                ? Colors.black.withValues(alpha: 0.06)
                                : Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: _showAppBarTitle ? null : Border.all(
                                color: Colors.white.withValues(alpha: 0.25), width: 1),
                          ),
                          child: Icon(Icons.ios_share_rounded,
                              color: _showAppBarTitle ? AppColors.ink : Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: ClipRect(
                child: Stack(fit: StackFit.expand, children: [
                  _maybeHeroImage(passion),
                  FadeTransition(
                    opacity: _gradientAnim,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.4, 0.7, 1.0],
                          colors: [
                            Colors.black.withValues(alpha: 0.25),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                            Colors.black.withValues(alpha: 0.92),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, left: 24, right: 24,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(passion.category.toUpperCase(),
                              style: GoogleFonts.firaSansCondensed(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.2,
                                  color: Colors.white.withValues(alpha: 0.5))),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(child: _maybeHeroTitle(passion)),
                              const SizedBox(width: 12),
                              AnimatedOpacity(
                                opacity: _showAppBarTitle ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Row(children: [
                                  HeroIconButton(
                                    icon: Icons.menu_book_outlined,
                                    label: 'Ressources',
                                    onTap: _openRessources,
                                  ),
                                  const SizedBox(width: 8),
                                  HeroIconButton(
                                    icon: Icons.lightbulb_outline_rounded,
                                    label: 'Bon à savoir',
                                    onTap: _openSecrets,
                                  ),
                                ]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ]),
                  ),
                ]),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── À PROPOS + CARTE ────────────────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      child: Stack(
                        children: [
                          DropCapText(text: passion.description),
                          if (passion.country.isNotEmpty)
                            Positioned(
                              top: 0, right: 0,
                              child: SizedBox(
                                width: 70, height: 70,
                                child: OriginBubble(
                                  key: ValueKey(passion.country),
                                  country: passion.country,
                                  passionId: passion.id,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── AUTOUR DE MOI + COMMUNAUTÉ (50/50) ──────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      delay: const Duration(milliseconds: 30),
                      child: SizedBox(
                        height: 70,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Autour de moi
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => NearbyScreen(passion: passion),
                                  ));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: primaryLight,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: primary.withValues(alpha: 0.18),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(children: [
                                    Container(
                                      width: 34, height: 34,
                                      decoration: BoxDecoration(
                                        color: primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.near_me_rounded,
                                          color: Colors.white, size: 17),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Autour de moi',
                                              style: GoogleFonts.firaSansCondensed(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: primary)),
                                          Text('Clubs & lieux',
                                              style: GoogleFonts.firaSansCondensed(
                                                  fontSize: 10.5,
                                                  color: primary.withValues(alpha: 0.6))),
                                        ],
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Voir la communauté
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => CommunityScreen(passion: passion),
                                  ));
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.cream,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: primary.withValues(alpha: 0.35),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(children: [
                                    Container(
                                      width: 34, height: 34,
                                      decoration: BoxDecoration(
                                        color: primaryLight,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.photo_library_outlined,
                                          color: primary, size: 17),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Communauté',
                                              style: GoogleFonts.firaSansCondensed(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.ink)),
                                          Text('Posts & Actus',
                                              style: GoogleFonts.firaSansCondensed(
                                                  fontSize: 10.5,
                                                  color: AppColors.inkSoft)),
                                        ],
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      delay: const Duration(milliseconds: 60),
                      child: ListenableBuilder(
                        listenable: _progress,
                        builder: (_, __) => ProgressCard(
                          progress: _progress,
                          onTap: _showProgressPopup,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ListenableBuilder(
                      listenable: _progress,
                      builder: (_, __) {
                        final isDone = _progress.started &&
                            _progress.globalPercent >= 1.0;
                        final isResume = _progress.started && !isDone;
                        return FadeInUp(
                          duration: const Duration(milliseconds: 300),
                          delay: const Duration(milliseconds: 130),
                          child: CTAButton(
                            onTap: isDone ? null : _openJourney,
                            isResume: isResume,
                            isDone: isDone,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}
