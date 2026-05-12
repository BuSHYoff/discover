import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/features/auth/screens/auth_screen.dart';
import 'package:discover/features/onboarding/screens/onboarding_screen.dart';
import 'package:discover/features/home/widgets/staggered_bounce.dart';
import 'package:discover/core/models/passion.dart';
import 'package:discover/core/services/auth_service.dart';
import 'package:discover/core/services/user_service.dart';
import 'package:discover/features/home/screens/detail_screen.dart';
import 'package:discover/features/journey/widgets/journey_progress.dart';
import 'package:discover/features/profile/widgets/stat_pill.dart';
import 'package:discover/features/profile/widgets/passion_row.dart';
import 'package:discover/features/profile/widgets/edit_name_sheet.dart';
import 'package:discover/core/services/community_service.dart';
import 'package:discover/features/home/widgets/community_models.dart';
import 'package:discover/features/home/widgets/post_detail_screen.dart';
import 'package:discover/core/theme/app_theme.dart';

// ─── PROFILE DATA ─────────────────────────────────────────────────────────────

class ProfileData extends ChangeNotifier {
  static final ProfileData _instance = ProfileData._();
  static ProfileData get instance => _instance;
  ProfileData._();

  String name = 'Toi';
  String profileColorHex = '#2D5A3D';
  final List<String> _uploadedPhotos = [];
  final Set<String> _viewedPassionIds = {};

  List<String> get uploadedPhotos => List.unmodifiable(_uploadedPhotos);
  Set<String> get viewedPassionIds => Set.unmodifiable(_viewedPassionIds);

  void markViewed(String passionId) {
    _viewedPassionIds.add(passionId);
    notifyListeners();
  }

  void addPhoto(String path) {
    _uploadedPhotos.insert(0, path);
    notifyListeners();
  }

  void removePhoto(String path) {
    _uploadedPhotos.remove(path);
    notifyListeners();
  }

  void setName(String n) {
    name = n;
    notifyListeners();
  }

  void setProfileColor(String hex) {
    profileColorHex = hex;
    notifyListeners();
  }

  void reset() {
    name = 'Toi';
    profileColorHex = '#2D5A3D';
    _uploadedPhotos.clear();
    _viewedPassionIds.clear();
    notifyListeners();
  }
}

// ─── FILTER TYPE ──────────────────────────────────────────────────────────────

enum PassionFilter { enCours, terminees }

extension PassionFilterLabel on PassionFilter {
  String get label {
    switch (this) {
      case PassionFilter.enCours:   return 'En cours';
      case PassionFilter.terminees: return 'Terminées';
    }
  }
  IconData get icon {
    switch (this) {
      case PassionFilter.enCours:   return Icons.access_time;
      case PassionFilter.terminees: return Icons.check_circle_outline_rounded;
    }
  }
}

// ─── COULEURS DE PROFIL ───────────────────────────────────────────────────────

const List<String> kProfileColors = [
  '#2D5A3D', // Vert forêt (défaut)
  '#4A8FCC', // Bleu azur
  '#8B6DB5', // Violet doux
  '#E07B54', // Corail
  '#D4789C', // Rose
  '#3DBDB5', // Turquoise
  '#CC6666', // Rouge doux
  '#6B7DC8', // Indigo
  '#C4A258', // Or
  '#48A870', // Vert menthe
  '#E8A838', // Ambre
  '#A0826D', // Terracotta
];

Color _hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

// ─── PROFILE SCREEN ───────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  final bool isGuest;
  const ProfileScreen({super.key, this.isGuest = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final Set<PassionFilter> _activeFilters = {};
  final ProfileData _profile = ProfileData.instance;

  // 0 = Mes passions, 1 = Mes publications
  int _selectedTab = 0;

  List<CommunityPost> _myPosts = [];

  @override
  void initState() {
    super.initState();
    _profile.addListener(_onProfileChanged);
    _loadMyPosts();
  }

  @override
  void dispose() {
    _profile.removeListener(_onProfileChanged);
    super.dispose();
  }

  /// Charge mes publications. Appelé à l'ouverture + sur pull-to-refresh.
  Future<void> _loadMyPosts() async {
    try {
      final posts = await CommunityService.fetchMyPosts();
      if (mounted) setState(() => _myPosts = posts);
    } catch (_) {
      if (mounted) setState(() => _myPosts = []);
    }
  }

  void _onProfileChanged() => setState(() {});

  void _toggleFilter(PassionFilter f) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_activeFilters.contains(f)) {
        _activeFilters.remove(f);
      } else {
        _activeFilters.add(f);
      }
    });
  }

  void _editName() {
    HapticFeedback.lightImpact();
    final ctrl = TextEditingController(text: _profile.name);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => EditNameSheet(
        controller: ctrl,
        onSave: (v) {
          _profile.setName(v);
          UserService.updateUsername(v);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _pickColor() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ColorPickerSheet(
        current: _profile.profileColorHex,
        onPick: (hex) {
          _profile.setProfileColor(hex);
          UserService.updateProfileColor(hex);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showLogoutModal() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.inkSoft.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 24),
            Text('Se déconnecter ?',
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
            const SizedBox(height: 8),
            Text(
              'Toutes tes données locales seront effacées.\nTu devras te reconnecter pour continuer.',
              textAlign: TextAlign.center,
              style: GoogleFonts.firaSansCondensed(
                  fontSize: 14, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD63B3B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Future.microtask(() => _showDeleteModal());
                },
                child: Text('Supprimer mon compte',
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: Color(0xFFD63B3B), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await AuthService.fullSignOut();
                  ProfileData.instance.reset();
                  JourneyProgress.resetAll();
                  CommunityService.clearUserCache();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const AuthScreen(),
                      transitionsBuilder: (_, __, ___, child) => child,
                      transitionDuration: Duration.zero,
                    ),
                    (_) => false,
                  );
                },
                child: Text('Se déconnecter',
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const Divider(height: 1, color: Color(0x14000000)),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Annuler',
                    style: GoogleFonts.firaSansCondensed(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Passion> _filteredPassions() {
    final started = allPassions.where((p) =>
        JourneyProgress.of(p.id).globalPercent > 0.0).toList();
    if (_activeFilters.isEmpty) return started;
    final Set<Passion> result = {};
    for (final f in _activeFilters) {
      switch (f) {
        case PassionFilter.enCours:
          result.addAll(started.where((p) {
            final pct = JourneyProgress.of(p.id).globalPercent;
            return pct > 0.0 && pct < 1.0;
          }));
        case PassionFilter.terminees:
          result.addAll(started.where((p) =>
              JourneyProgress.of(p.id).globalPercent >= 1.0));
      }
    }
    return result.toList();
  }

  int get _enCoursCount => allPassions.where((p) {
    final pct = JourneyProgress.of(p.id).globalPercent;
    return pct > 0.0 && pct < 1.0;
  }).length;

  int get _termineesCount => allPassions
      .where((p) => JourneyProgress.of(p.id).globalPercent >= 1.0)
      .length;

  void _showDeleteModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Supprimer le compte ?',
            style: GoogleFonts.firaSansCondensed(
                fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
        content: Text(
            'Cette action est irréversible. Toutes tes données et publications seront supprimées.',
            style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.inkSoft)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 15, color: AppColors.inkSoft)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteAccount();
            },
            child: Text('Supprimer',
                style: GoogleFonts.firaSansCondensed(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    // Tente la suppression Firestore + Auth — on continue même en cas d'erreur
    try {
      await UserService.deleteAccount();
    } catch (_) {}

    // Nettoyage local garanti, quelle que soit l'issue
    try { await AuthService.fullSignOut(); } catch (_) {}
    await OnboardingData.instance.reset();
    CommunityService.clearUserCache();
    JourneyProgress.resetAll();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const OnboardingScreen(),
        transitionsBuilder: (_, __, ___, child) => child,
        transitionDuration: Duration.zero,
      ),
      (_) => false,
    );
  }

  Widget _buildGuestScreen(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: GoogleFonts.firaSansCondensed(
                    fontSize: 42, fontWeight: FontWeight.w900,
                    color: AppColors.ink, height: 1.05,
                  ),
                  children: [
                    const TextSpan(text: 'Rejoins\nDiscover'),
                    TextSpan(text: '.', style: TextStyle(color: primary)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Crée un compte pour sauvegarder tes passions, suivre ta progression et rejoindre la communauté.',
                style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.inkSoft, fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                },
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Créer un compte',
                    style: GoogleFonts.firaSansCondensed(
                      fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isGuest) return _buildGuestScreen(context);

    final topPadding    = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final passions      = _filteredPassions();
    // Hauteur totale de la bottom bar (72 contenu + 16 marge + safe area)
    final barHeight     = bottomPadding + 88.0;

    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: RefreshIndicator(
        color: primary,
        onRefresh: _loadMyPosts,
        child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [

          // ── HEADER ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  StaggeredBounceEntry(
                    index: 0,
                    child: Builder(builder: (context) {
                      final primary = Theme.of(context).colorScheme.primary;
                      final primaryLight = Color.lerp(primary, Colors.white, 0.82)!;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: GoogleFonts.firaSansCondensed(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                                height: 1.05,
                              ),
                              children: [
                                const TextSpan(text: 'Profil'),
                                TextSpan(text: '.', style: TextStyle(color: primary)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Se déconnecter (rouge)
                          GestureDetector(
                            onTap: _showLogoutModal,
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.logout_rounded,
                                  color: AppColors.error, size: 20),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: 5),

                  StaggeredBounceEntry(
                    index: 1,
                    child: Text(
                      'Tes passions et ta progression.',
                      style: GoogleFonts.firaSansCondensed(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.inkSoft,
                          letterSpacing: -0.1),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Avatar lettre + nom ──────────────────────────────
                  StaggeredBounceEntry(
                    index: 2,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar : première lettre du nom + couleur choisie
                        GestureDetector(
                          onTap: _pickColor,
                          child: Stack(children: [
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _hexToColor(_profile.profileColorHex).withValues(alpha: 0.7),
                                    _hexToColor(_profile.profileColorHex),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _hexToColor(_profile.profileColorHex).withValues(alpha: 0.45),
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _profile.name.length >= 2
                                      ? _profile.name.substring(0, 2).toUpperCase()
                                      : _profile.name.isNotEmpty
                                          ? _profile.name[0].toUpperCase()
                                          : '?',
                                  style: GoogleFonts.firaSansCondensed(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            // Pastille couleur
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.black.withValues(alpha: 0.1)),
                                ),
                                child: Icon(Icons.palette_outlined,
                                    size: 12,
                                    color: _hexToColor(_profile.profileColorHex)),
                              ),
                            ),
                          ]),
                        ),

                        const SizedBox(width: 16),

                        // Nom
                        Expanded(
                          child: GestureDetector(
                            onTap: _editName,
                            child: Row(children: [
                              Flexible(
                                child: Text(
                                  _profile.name,
                                  style: GoogleFonts.firaSansCondensed(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 26, height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.edit_rounded,
                                    size: 13, color: AppColors.inkSoft),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Stats ────────────────────────────────────────────
                  StaggeredBounceEntry(
                    index: 3,
                    child: Builder(builder: (context) {
                      final pt = ProfileTheme.fromHex(_profile.profileColorHex);
                      return Row(children: [
                        StatPill(
                          value: _enCoursCount,
                          label: 'En cours',
                          color: pt.primary,
                          bgColor: pt.light,
                        ),
                        const SizedBox(width: 8),
                        StatPill(
                          value: _termineesCount,
                          label: 'Terminées',
                          color: const Color(0xFF7B5EA7),
                          bgColor: const Color(0xFFF0EBFB),
                        ),
                        const SizedBox(width: 8),
                        StatPill(
                          value: _myPosts.length,
                          label: 'Publications',
                          color: const Color(0xFF3D7FCC),
                          bgColor: const Color(0xFFEBF2FB),
                        ),
                      ]);
                    }),
                  ),
                ],
              ),
            ),
          ),

          // ── TAB BAR ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Builder(builder: (context) {
                final pt = ProfileTheme.fromHex(_profile.profileColorHex);
                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    _TabButton(
                      label: 'Mes passions',
                      icon: Icons.local_fire_department_rounded,
                      isActive: _selectedTab == 0,
                      activeColor: pt.primary,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTab = 0);
                      },
                    ),
                    const SizedBox(width: 4),
                    _TabButton(
                      label: 'Publications',
                      icon: Icons.photo_library_outlined,
                      isActive: _selectedTab == 1,
                      activeColor: pt.primary,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTab = 1);
                      },
                    ),
                  ]),
                );
              }),
            ),
          ),

          // ── CONTENU PASSIONS ──────────────────────────────────────────
          if (_selectedTab == 0) ...[
            // Filtres
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Builder(builder: (context) {
                  final pt = ProfileTheme.fromHex(_profile.profileColorHex);
                  return Row(children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: PassionFilter.values.map((f) {
                            final isActive = _activeFilters.contains(f);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => _toggleFilter(f),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isActive ? pt.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: isActive
                                          ? pt.primary
                                          : Colors.black.withValues(alpha: 0.08),
                                    ),
                                    boxShadow: isActive ? [] : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(f.icon,
                                          size: 13,
                                          color: isActive ? Colors.white : AppColors.inkSoft),
                                      const SizedBox(width: 6),
                                      Text(f.label,
                                          style: GoogleFonts.firaSansCondensed(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isActive ? Colors.white : AppColors.ink)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    if (_activeFilters.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _activeFilters.clear());
                        },
                        child: Text('Tout voir',
                            style: GoogleFonts.firaSansCondensed(
                                fontSize: 12,
                                color: pt.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ]);
                }),
              ),
            ),
            // Liste passions
            passions.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 40),
                      child: Center(
                        child: Column(children: [
                          Icon(Icons.rocket_launch_outlined,
                              size: 40,
                              color: AppColors.inkSoft.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('Commence une passion pour la voir ici !',
                              style: GoogleFonts.firaSansCondensed(
                                  fontSize: 14, color: AppColors.inkSoft)),
                        ]),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => StaggeredBounceEntry(
                          index: index,
                          direction: BounceDirection.fromBottom,
                          initialDelay: const Duration(milliseconds: 80),
                          staggerDelay: const Duration(milliseconds: 55),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PassionRow(
                              passion: passions[index],
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).push(PageRouteBuilder(
                                  pageBuilder: (_, __, ___) =>
                                      DetailScreen(passion: passions[index]),
                                  transitionsBuilder: (_, animation, __, child) =>
                                      FadeTransition(
                                    opacity: CurvedAnimation(
                                      parent: animation,
                                      curve: const Interval(0.3, 1.0,
                                          curve: Curves.easeOut),
                                    ),
                                    child: child,
                                  ),
                                  transitionDuration:
                                      const Duration(milliseconds: 480),
                                  reverseTransitionDuration:
                                      const Duration(milliseconds: 480),
                                ));
                              },
                            ),
                          ),
                        ),
                        childCount: passions.length,
                      ),
                    ),
                  ),
          ],

          // ── CONTENU PUBLICATIONS ──────────────────────────────────────
          if (_selectedTab == 1)
            _myPosts.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 40),
                      child: Center(
                        child: Column(children: [
                          Icon(Icons.photo_camera_outlined,
                              size: 40,
                              color: AppColors.inkSoft.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('Aucune publication pour l\'instant.',
                              style: GoogleFonts.firaSansCondensed(
                                  fontSize: 14, color: AppColors.inkSoft)),
                        ]),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = _myPosts[index];
                          return StaggeredBounceEntry(
                            index: index,
                            direction: BounceDirection.fromBottom,
                            initialDelay: const Duration(milliseconds: 60),
                            staggerDelay: const Duration(milliseconds: 40),
                            child: _PostThumb(post: post),
                          );
                        },
                        childCount: _myPosts.length,
                      ),
                    ),
                  ),

          // Padding final pour la bottom bar
          SliverToBoxAdapter(child: SizedBox(height: barHeight)),
        ],
      ),
      ),
    );
  }
}

// ─── TAB BUTTON ───────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: isActive ? Colors.white : AppColors.inkSoft),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.firaSansCondensed(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppColors.inkSoft)),
            ],
          ),
        ),
      ),
    );
  }
}


class _PostThumb extends StatelessWidget {
  final CommunityPost post;
  const _PostThumb({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final passion = allPassions
            .where((p) => p.id == post.passionId)
            .firstOrNull;
        if (passion == null) return;
        Navigator.of(context).push(PageRouteBuilder(
          pageBuilder: (_, __, ___) => PostDetailScreen(
            post:    post,
            passion: passion,
            onLike:  () => CommunityService.toggleLike(
                post.id, !post.isLiked, post.passionId),
          ),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 350),
        ));
      },
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(fit: StackFit.expand, children: [
          Image.network(
            post.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.greenLight,
              child: Icon(Icons.image_outlined,
                  color: AppColors.inkSoft, size: 28),
            ),
          ),
          // Overlay dégradé + stats + expand
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.favorite_rounded,
                      size: 10, color: Colors.white.withValues(alpha: 0.9)),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text('${post.likeCount}',
                        style: GoogleFonts.firaSansCondensed(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                  const Icon(Icons.open_in_full_rounded,
                      size: 10, color: Colors.white),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _PostsEmpty extends StatelessWidget {
  final Color primary;
  final Color primaryLight;
  const _PostsEmpty({required this.primary, required this.primaryLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.photo_camera_outlined, size: 17, color: primary),
        ),
        const SizedBox(width: 12),
        Text(
          'Aucune publication pour l\'instant.',
          style: GoogleFonts.firaSansCondensed(
              fontSize: 13, color: AppColors.inkSoft),
        ),
      ]),
    );
  }
}

// ─── COLOR PICKER SHEET ───────────────────────────────────────────────────────

class _ColorPickerSheet extends StatelessWidget {
  final String current;
  final ValueChanged<String> onPick;

  const _ColorPickerSheet({required this.current, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: AppColors.cream,
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Couleur du profil',
              style: GoogleFonts.firaSansCondensed(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: kProfileColors.map((hex) {
              final isSelected = hex == current;
              return GestureDetector(
                onTap: () => onPick(hex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hexToColor(hex),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: _hexToColor(hex).withValues(alpha: 0.4),
                        blurRadius: isSelected ? 12 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }
}
