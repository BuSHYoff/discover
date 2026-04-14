import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:discover/core/services/user_service.dart';
import 'package:discover/core/services/notification_service.dart';
import 'package:discover/core/services/community_service.dart';
import 'package:discover/features/auth/widgets/page_auth.dart';
import 'package:discover/features/onboarding/screens/onboarding_screen.dart';
import 'package:discover/features/profile/screens/profile_screen.dart';
import 'package:discover/main_shell.dart';
import 'package:discover/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AUTH SCREEN — écran standalone utilisé après déconnexion.
// La vérification se fait via Firestore (champ `username` dans users/{uid}).
// Pas de dépendance à displayName Firebase qui peut être absent ou périmé.
// ─────────────────────────────────────────────────────────────────────────────

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: PageAuth(
          onContinueAsGuest: () async {
            await OnboardingData.markDoneAsGuest();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const MainShell(isGuest: true),
                transitionsBuilder: (_, __, ___, child) => child,
                transitionDuration: Duration.zero,
              ),
              (_) => false,
            );
          },
          onAuthSuccess: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) return;

            // ── 1. Reset complet de l'état local ─────────────────────────────
            // Évite que la couleur/pseudo du compte précédent restent affichés.
            ProfileData.instance.reset();
            // Vide le cache auteurs pour forcer un re-fetch avec le nouveau compte
            CommunityService.clearUserCache();

            // ── 2. Lecture Firestore (1 seul read) ───────────────────────────
            final profile = await UserService.loadUserProfile();
            final hasAccount = profile.username?.isNotEmpty == true;

            if (hasAccount) {
              // Compte existant → applique username + couleur depuis Firestore
              ProfileData.instance.setName(profile.username!);
              if (profile.profileColor?.isNotEmpty == true) {
                ProfileData.instance.setProfileColor(profile.profileColor!);
              }

              // Restaure les passions en cours / terminées depuis Firestore
              await UserService.loadAndRestorePassions();

              // Marque l'onboarding comme terminé en local pour les prochains lancements
              await OnboardingData.markDone();

              // Enregistre le token FCM pour les notifications
              await NotificationService.initFcmToken();
            }

            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    hasAccount ? const MainShell() : const OnboardingScreen(),
                transitionsBuilder: (_, anim, __, child) => FadeTransition(
                  opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 500),
              ),
              (_) => false,
            );
          },
        ),
      ),
    );
  }
}
