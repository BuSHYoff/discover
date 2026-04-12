import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:discover/core/services/user_service.dart';
import 'package:discover/core/services/notification_service.dart';
import 'package:discover/features/auth/widgets/page_auth.dart';
import 'package:discover/features/onboarding/screens/onboarding_screen.dart';
import 'package:discover/features/profile/screens/profile_screen.dart';
import 'package:discover/main_shell.dart';
import 'package:discover/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AUTH SCREEN — écran standalone utilisé après déconnexion.
// Si l'utilisateur a déjà complété l'onboarding (displayName non vide),
// on l'envoie directement sur MainShell. Sinon, on relance l'onboarding.
// ─────────────────────────────────────────────────────────────────────────────

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: PageAuth(
          onAuthSuccess: () async {
            final user = FirebaseAuth.instance.currentUser;
            final hasCompletedOnboarding =
                user?.displayName != null && user!.displayName!.isNotEmpty;

            if (hasCompletedOnboarding) {
              // Utilisateur connu → restaure nom + progress des passions
              ProfileData.instance.setName(user.displayName!);
              await UserService.loadAndRestorePassions();
              await NotificationService.initFcmToken();
            }

            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    hasCompletedOnboarding ? const MainShell() : const OnboardingScreen(),
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
