import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:discover/main_shell.dart';
import 'package:discover/core/services/user_service.dart';
import 'package:discover/features/onboarding/widgets/onboarding_models.dart';
import 'package:discover/features/onboarding/widgets/page1.dart';
import 'package:discover/features/onboarding/widgets/page2.dart';
import 'package:discover/features/onboarding/widgets/page3.dart';
import 'package:discover/features/onboarding/widgets/page4.dart';
import 'package:discover/features/auth/widgets/page_auth.dart';
import 'package:discover/features/onboarding/widgets/continue_button.dart';
import 'package:discover/features/profile/screens/profile_screen.dart';
import 'package:discover/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ONBOARDING DATA  (singleton — persisté via SharedPreferences)
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingData extends ChangeNotifier {
  static final OnboardingData _instance = OnboardingData._();
  static OnboardingData get instance => _instance;
  OnboardingData._();

  // Réponses collectées pendant l'onboarding
  String hobbyRelation      = '';          // écran 1
  List<String> universes      = [];          // écran 2  (max 3)
  String timePerWeek    = '';          // écran 3
  String budget             = '';          // écran 3
  String firstName             = '';          // écran 4

  static const _keyDone      = 'onboarding_done';
  static const _keyRelation  = 'onboarding_relation';
  static const _keyUniverses   = 'onboarding_univers';
  static const _keyTime     = 'onboarding_temps';
  static const _keyBudget    = 'onboarding_budget';
  static const _keyFirstName    = 'onboarding_prenom';

  /// Vérifie si l'onboarding a déjà été complété
  static Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDone) ?? false;
  }

  /// Marque l'onboarding comme terminé sans sauvegarder les autres champs.
  /// Utilisé quand un compte existant est détecté (on saute l'onboarding).
  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDone, true);
  }

  /// Charge les données sauvegardées
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    hobbyRelation   = prefs.getString(_keyRelation) ?? '';
    universes         = prefs.getStringList(_keyUniverses) ?? [];
    timePerWeek = prefs.getString(_keyTime) ?? '';
    budget          = prefs.getString(_keyBudget) ?? '';
    firstName          = prefs.getString(_keyFirstName) ?? '';
    notifyListeners();
  }

  /// Sauvegarde et marque l'onboarding comme terminé
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDone, true);
    await prefs.setString(_keyRelation, hobbyRelation);
    await prefs.setStringList(_keyUniverses, universes);
    await prefs.setString(_keyTime, timePerWeek);
    await prefs.setString(_keyBudget, budget);
    await prefs.setString(_keyFirstName, firstName);
    notifyListeners();
  }

  /// Réinitialise (utile pour les tests ou un "reset profil")
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDone);
    await prefs.remove(_keyRelation);
    await prefs.remove(_keyUniverses);
    await prefs.remove(_keyTime);
    await prefs.remove(_keyBudget);
    await prefs.remove(_keyFirstName);
    hobbyRelation = ''; universes = []; timePerWeek = '';
    budget = ''; firstName = '';
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONBOARDING SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {

  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  // Animations de transition entre pages
  late AnimationController _fadeCtrl;
  late Animation<double>    _fadeAnim;

  // Données collectées (miroir local de OnboardingData)
  String       _hobbyRelation   = '';
  List<String> _universes         = [];
  String       _timePerWeek = '';
  String       _budget          = '';
  final TextEditingController _firstNameCtrl = TextEditingController();

  // Focus node pour le champ prénom
  final FocusNode _firstNameFocus = FocusNode();

  // ── Données des choix ────────────────────────────────────────────────────

  static const _relations = [
    OnboardingChoice('Je ne sais pas par où commencer', '🌱',
        'Tout est à découvrir — c\'est excitant.'),
    OnboardingChoice('J\'en ai eu mais je n\'approfondis pas', '🍃',
        'On va retrouver cette étincelle.'),
    OnboardingChoice('J\'en ai déjà plein, je veux élargir', '🌍',
        'Parfait pour explorer de nouveaux horizons.'),
  ];

  static const _universeChoices = [
    OnboardingUniverseChoice('Art & Créativité',    '🎨', Color(0xFFF5E6D3), Color(0xFF8B5E3C)),
    OnboardingUniverseChoice('Corps & Mouvement',   '💪', Color(0xFFE8F0EB), AppColors.green),
    OnboardingUniverseChoice('Nature & Exploration','🌿', Color(0xFFECF5E8), Color(0xFF3A6B2C)),
    OnboardingUniverseChoice('Gastronomie',         '🍳', Color(0xFFF5EBE0), Color(0xFF8B4513)),
    OnboardingUniverseChoice('Musique & Son',       '🎵', Color(0xFFEBE8F5), Color(0xFF4B3A8B)),
    OnboardingUniverseChoice('Sciences & Tech',     '🔬', Color(0xFFF0EBF5), Color(0xFF5C3A8B)),
  ];

  static const _timeChoices = [
    OnboardingChoice('Moins de 2h',    '⏱️', 'Des sessions courtes et régulières.'),
    OnboardingChoice('Entre 2h et 5h', '⌛',  'Un bon équilibre pour progresser.'),
    OnboardingChoice('Plus de 5h',     '📈', 'Tu vas aller loin !'),
  ];

  static const _budgetChoices = [
    OnboardingChoice('Gratuit ou presque', '🪙', 'On trouve des pépites sans dépenser.'),
    OnboardingChoice('Jusqu\'à 50€',       '💳', 'De quoi bien démarrer.'),
    OnboardingChoice('Pas de limite',      '💎', 'Le meilleur matériel dès le début.'),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    _firstNameCtrl.dispose();
    _firstNameFocus.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  bool get _canGoNext {
    switch (_currentPage) {
      case 0: return _hobbyRelation.isNotEmpty;
      case 1: return _universes.isNotEmpty;
      case 2: return _timePerWeek.isNotEmpty && _budget.isNotEmpty;
      case 3: return false;   // auth — avance via onAuthSuccess, pas le bouton
      case 4: return _firstNameCtrl.text.trim().isNotEmpty;
      default: return false;
    }
  }

  Future<void> _nextPage() async {
    HapticFeedback.lightImpact();
    if (_currentPage < 4) {
      await _fadeCtrl.reverse();
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentPage++);
      _fadeCtrl.forward();
      // Auto-focus sur le champ prénom à l'écran 5
      if (_currentPage == 4) {
        Future.delayed(const Duration(milliseconds: 450), () {
          if (mounted) _firstNameFocus.requestFocus();
        });
      }
    } else {
      await _finish();
    }
  }

  /// Appelé par PageAuth quand Firebase auth réussit.
  /// Si l'utilisateur a déjà un compte Firestore → saute la page du pseudo
  /// et va directement dans MainShell.
  Future<void> _onAuthSuccess() async {
    final profile = await UserService.loadUserProfile();
    final hasAccount = profile.username?.isNotEmpty == true;

    if (!mounted) return;

    if (hasAccount) {
      // Compte existant : charge tout depuis Firestore et va dans l'app
      ProfileData.instance.reset();
      ProfileData.instance.setName(profile.username!);
      if (profile.profileColor?.isNotEmpty == true) {
        ProfileData.instance.setProfileColor(profile.profileColor!);
      }
      await UserService.loadAndRestorePassions();
      // Marque l'onboarding comme terminé pour les prochains lancements
      await OnboardingData.markDone();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      // Nouveau compte → page du pseudo
      _nextPage();
    }
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    final data = OnboardingData.instance;
    data.hobbyRelation = _hobbyRelation;
    data.universes     = List.from(_universes);
    data.timePerWeek   = _timePerWeek;
    data.budget        = _budget;
    data.firstName     = _firstNameCtrl.text.trim();
    await data.save();

    // Met à jour le nom affiché dans le profil
    ProfileData.instance.setName(data.firstName);

    // Synchronise aussi le displayName Firebase Auth
    // (try/catch : peut échouer si le token vient juste d'être créé)
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      await FirebaseAuth.instance.currentUser?.updateDisplayName(data.firstName);
    } catch (_) {
      // Non-critique : le username est déjà dans ProfileData et Firestore
    }

    // Crée ou met à jour le document utilisateur dans Firestore
    await UserService.saveUser(
      username:      data.firstName,
      hobbyRelation: data.hobbyRelation,
      universes:     data.universes,
      timePerWeek:   data.timePerWeek,
      budget:        data.budget,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── Barre de progression ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Builder(builder: (context) {
                final primary = Theme.of(context).colorScheme.primary;
                return Row(
                  children: List.generate(5, (i) {
                    final done    = i < _currentPage;
                    final current = i == _currentPage;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.only(right: 6),
                        height: 3,
                        decoration: BoxDecoration(
                          color: done || current
                              ? primary
                              : primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),

            // ── Contenu paginé ────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Page1(
                    selected: _hobbyRelation,
                    choices: _relations,
                    onSelect: (v) => setState(() => _hobbyRelation = v),
                  ),
                  Page2(
                    selected: _universes,
                    choices: _universeChoices,
                    onToggle: (v) {
                      setState(() {
                        if (_universes.contains(v)) {
                          _universes.remove(v);
                        } else if (_universes.length < 3) {
                          _universes.add(v);
                        }
                      });
                    },
                  ),
                  Page3(
                    selectedTime:  _timePerWeek,
                    selectedBudget: _budget,
                    timeChoices:   _timeChoices,
                    budgetChoices:  _budgetChoices,
                    onSelectTime:  (v) => setState(() => _timePerWeek = v),
                    onSelectBudget: (v) => setState(() => _budget = v),
                  ),
                  PageAuth(
                    onAuthSuccess: _onAuthSuccess,
                  ),
                  Page4(
                    controller: _firstNameCtrl,
                    focusNode:  _firstNameFocus,
                    onChanged:  (_) => setState(() {}),
                  ),
                ],
              ),
            ),

            // ── Bouton Continuer (masqué sur la page auth) ────────────────
            if (_currentPage != 3)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24, 0, 24,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ContinueButton(
                    label: _currentPage < 4 ? 'Continuer' : 'C\'est parti !',
                    enabled: _canGoNext,
                    onTap: _canGoNext ? _nextPage : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
