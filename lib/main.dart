import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:discover/core/services/firebase_options.dart';
import 'package:discover/core/services/notification_service.dart';
import 'package:discover/core/services/passions_service.dart';
import 'package:discover/core/services/user_service.dart';
import 'package:discover/core/theme/app_theme.dart';
import 'package:discover/features/onboarding/onboarding.dart';
import 'package:discover/features/profile/screens/profile_screen.dart';
import 'package:discover/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Firebase Auth + Messaging restent : nécessaires pour générer l'ID Token
  // Bearer envoyé à l'API NestJS et pour recevoir les notifications push.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService.initialize();

  // Google Sign In (requis pour les comptes Google)
  await GoogleSignIn.instance.initialize(
    serverClientId: '240632493418-afu40a0d2t2rr0oblvncgo8vtvrt5pug.apps.googleusercontent.com',
  );

  // Charge le catalogue de passions via l'API (un seul GET /passions)
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

  runApp(DiscoverApp(showOnboarding: !onboardingDone, isGuest: isGuest));
}

class DiscoverApp extends StatefulWidget {
  final bool showOnboarding;
  final bool isGuest;

  const DiscoverApp({super.key, required this.showOnboarding, this.isGuest = false});

  @override
  State<DiscoverApp> createState() => _DiscoverAppState();
}

class _DiscoverAppState extends State<DiscoverApp> {
  @override
  void initState() {
    super.initState();
    ProfileData.instance.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    ProfileData.instance.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discover.',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.fromHex(ProfileData.instance.profileColorHex),
      home: widget.showOnboarding ? const OnboardingScreen() : MainShell(isGuest: widget.isGuest),
    );
  }
}
