import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:discover/features/home/widgets/staggered_bounce.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/features/home/screens/detail_screen.dart';
import 'package:discover/features/explorer/widgets/section_header.dart';
import 'package:discover/features/explorer/widgets/weekly_passion_card.dart';
import 'package:discover/features/explorer/widgets/trend_row.dart';
import 'package:discover/core/services/trending_service.dart';
import 'package:discover/core/services/weekly_passion_service.dart';
import 'package:discover/core/theme/app_theme.dart';

// ─── EXPLORER SCREEN ──────────────────────────────────────────────────────────

class ExplorerScreen extends StatefulWidget {
  /// Incrémenté par MainShell à chaque fois qu'on revient sur cet onglet.
  /// Déclenche le rejeu des animations sans recharger les données.
  final int animKey;

  const ExplorerScreen({super.key, this.animKey = 0});

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {

  // ── Données (chargées une seule fois, rechargées sur pull-to-refresh) ───────
  List<TrendItem>?   _trends;
  WeeklyPassionData? _weekly;
  bool _loading = false;

  final ScrollController _scrollCtrl = ScrollController();

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(ExplorerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Retour sur l'onglet → scroll en haut
    if (widget.animKey != oldWidget.animKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_loading) return;
    setState(() { _loading = true; });

    // Chargement en parallèle mais indépendant :
    // un échec d'un côté ne bloque pas l'autre
    final trendsResult = TrendingService.fetchTrends(limit: 5);
    final weeklyResult = WeeklyPassionService.fetch();

    final trends = await trendsResult;
    final weekly = await weeklyResult;

    if (mounted) {
      setState(() {
        _trends  = trends;
        _weekly  = weekly;
        _loading = false;
      });
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _openDetail(Passion passion) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:        (_, __, ___) => DetailScreen(passion: passion),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
          child: child,
        ),
        transitionDuration:        const Duration(milliseconds: 480),
        reverseTransitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: RefreshIndicator(
        onRefresh:   _loadData,
        color:       Theme.of(context).colorScheme.primary,
        strokeWidth: 2.5,
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [

            // ── HEADER ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: KeyedSubtree(
                    // animKey change → les StaggeredBounce se rejouent
                    key: ValueKey('header_${widget.animKey}'),
                    child: StaggeredBounceEntry(
                      index: 0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    style: GoogleFonts.firaSansCondensed(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.ink,
                                        height: 1.05),
                                    children: [
                                      const TextSpan(text: 'Explorer'),
                                      TextSpan(
                                        text: '.',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ton espace d\'exploration',
                                  style: GoogleFonts.firaSansCondensed(
                                      fontSize: 13, color: AppColors.inkSoft),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── PASSION DE LA SEMAINE ────────────────────────────────────────
            if (_weekly != null)
              SliverToBoxAdapter(
                child: KeyedSubtree(
                  key: ValueKey('weekly_${widget.animKey}'),
                  child: StaggeredBounceEntry(
                    index: 1,
                    direction: BounceDirection.fromBottom,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: WeeklyPassionCard(
                        passion: _weekly!.passion,
                        angle:   _weekly!.description,
                        onTap:   () => _openDetail(_weekly!.passion),
                      ),
                    ),
                  ),
                ),
              ),
            if (_weekly != null)
              const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // ── SECTION TENDANCES ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KeyedSubtree(
                    key: ValueKey('trends_header_${widget.animKey}'),
                    child: StaggeredBounceEntry(
                      index: 2,
                      direction: BounceDirection.fromBottom,
                      child: SectionHeader(
                        title:    'Tendances',
                        subtitle: 'Ce que la communauté explore',
                        icon:     Icons.trending_up_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildTrendsList(),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // ── DÉFIS COMMUNAUTAIRES — BIENTÔT ──────────────────────────────
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: ValueKey('challenges_${widget.animKey}'),
                child: StaggeredBounceEntry(
                  index: 4,
                  direction: BounceDirection.fromBottom,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Builder(builder: (context) {
                      final primary = Theme.of(context).colorScheme.primary;
                      final primaryLight =
                          Color.lerp(primary, Colors.white, 0.82)!;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 24),
                        decoration: BoxDecoration(
                          color: primaryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.local_fire_department_rounded,
                                color: primary, size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Défis communautaires',
                                    style: GoogleFonts.firaSansCondensed(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Bientôt disponible',
                                    style: GoogleFonts.firaSansCondensed(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'Arrive bientôt',
                                style: GoogleFonts.firaSansCondensed(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
                child: SizedBox(height: bottomPadding + 120)),
          ],
        ),
      ),
    );
  }

  // ── Widget tendances (loader / erreur / données) ──────────────────────────

  Widget _buildTrendsList() {
    // Chargement initial
    if (_loading && _trends == null) {
      return _TrendsSkeleton();
    }

    // Données disponibles (toujours au moins 5 items grâce au fallback catalogue)
    final items = _trends ?? [];
    return KeyedSubtree(
      key: ValueKey('trends_list_${widget.animKey}'),
      child: Column(
        children: List.generate(items.length, (i) {
          final item    = items[i];
          final passion = item.passion;
          return StaggeredBounceEntry(
            index:        i,
            direction:    BounceDirection.fromBottom,
            initialDelay: const Duration(milliseconds: 120),
            staggerDelay: const Duration(milliseconds: 60),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TrendRow(
                rank:    i + 1,
                passion: passion,
                trend:   item,
                onTap:   () => _openDetail(passion),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Skeleton loader ──────────────────────────────────────────────────────────

class _TrendsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Container(width: 28, height: 16,
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6))),
              const SizedBox(width: 10),
              Container(width: 48, height: 48,
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 12, width: 120,
                        decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 70,
                        decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }
}

