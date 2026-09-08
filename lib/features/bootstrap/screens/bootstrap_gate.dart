import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:discover/core/api/api_exception.dart';
import 'package:discover/core/services/firebase_options.dart';
import 'package:discover/core/services/notification_service.dart';
import 'package:discover/core/services/passions_service.dart';
import 'package:discover/core/services/user_service.dart';
import 'package:discover/core/theme/app_theme.dart';
import 'package:discover/features/bootstrap/widgets/boot_error_view.dart';
import 'package:discover/features/bootstrap/widgets/boot_loading_view.dart';
import 'package:discover/features/onboarding/onboarding.dart';
import 'package:discover/features/profile/screens/profile_screen.dart';

/// Racine de l'app : joue la séquence de démarrage derrière un loader, puis
/// laisse la place à l'app réelle via [builder].
///
/// Auparavant cette séquence vivait dans `main()`, avant `runApp()` : la
/// moindre exception (backend indisponible, réseau coupé) empêchait toute
/// interface de s'afficher. Ici l'UI est montée immédiatement et l'échec
/// devient un écran d'erreur avec bouton « Réessayer ».
class BootstrapGate extends StatefulWidget {
  /// Construit l'app une fois le démarrage terminé.
  final Widget Function(bool showOnboarding, bool isGuest) builder;

  const BootstrapGate({super.key, required this.builder});

  @override
  State<BootstrapGate> createState() => _BootstrapGateState();
}

enum _BootPhase { loading, ready, failed }

class _BootstrapGateState extends State<BootstrapGate> {
  /// Les init natives ne sont jouées qu'une fois : les rejouer sur un
  /// « Réessayer » lèverait un duplicate-app côté Firebase.
  static bool _nativeReady = false;

  _BootPhase _phase = _BootPhase.loading;
  String     _error = '';
  bool       _showOnboarding = false;
  bool       _isGuest        = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    if (mounted) setState(() => _phase = _BootPhase.loading);

    try {
      if (!_nativeReady) {
        // Firebase Auth + Messaging : nécessaires pour générer l'ID Token
        // Bearer envoyé à l'API NestJS et pour recevoir les notifications push.
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        await NotificationService.initialize();

        // Google Sign In (requis pour les comptes Google)
        await GoogleSignIn.instance.initialize(
          serverClientId:
              '240632493418-afu40a0d2t2rr0oblvncgo8vtvrt5pug.apps.googleusercontent.com',
        );
        _nativeReady = true;
      }

      // Charge le catalogue de passions via l'API (un seul GET /passions).
      // ApiClient retente en interne tant que l'erreur est transitoire, le
      // temps qu'une instance Cloud Run démarre.
      await PassionsService.loadCatalog();

      // Vérifie si l'onboarding a déjà été complété (état local SharedPreferences)
      final onboardingDone = await OnboardingData.isDone();
      final isGuest        = await OnboardingData.isGuest();

      if (onboardingDone) {
        await OnboardingData.instance.load();
        final name = OnboardingData.instance.firstName;
        if (name.isNotEmpty) ProfileData.instance.setName(name);
      }

      // User connecté : restaure profil + progressions depuis le backend.
      if (!isGuest && FirebaseAuth.instance.currentUser != null) {
        final results = await Future.wait([
          UserService.loadAndRestorePassions(),
          UserService.loadUserProfile(),
        ]);

        final profile = results[1] as ({String? username, String? profileColor});
        if (profile.username?.isNotEmpty == true) {
          ProfileData.instance.setName(profile.username!);
        }
        if (profile.profileColor?.isNotEmpty == true) {
          ProfileData.instance.setProfileColor(profile.profileColor!);
        }
      }

      // Écouteur de rotation FCM token — sans popup permission.
      NotificationService.setupTokenRefreshListener();

      if (!mounted) return;
      setState(() {
        _showOnboarding = !onboardingDone;
        _isGuest        = isGuest;
        _phase          = _BootPhase.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _describe(e);
        _phase = _BootPhase.failed;
      });
    }
  }

  /// Traduit l'erreur technique en message lisible par l'utilisateur.
  static String _describe(Object e) {
    if (e is ApiException) {
      if (e.isThrottled || e.isServerError) {
        return 'Le serveur ne répond pas pour le moment. '
               'Il redémarre peut-être — réessayez dans quelques secondes.';
      }
      return 'Le serveur a renvoyé une erreur inattendue (${e.status}).';
    }
    if (e is SocketException || e is TimeoutException) {
      return 'Impossible de joindre le serveur. '
             'Vérifiez votre connexion internet, puis réessayez.';
    }
    return 'Une erreur est survenue au démarrage de l\'application.';
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _BootPhase.ready) {
      return widget.builder(_showOnboarding, _isGuest);
    }

    return MaterialApp(
      title: 'Discover.',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: _phase == _BootPhase.failed
          ? BootErrorView(message: _error, onRetry: _boot)
          : const BootLoadingView(),
    );
  }
}
