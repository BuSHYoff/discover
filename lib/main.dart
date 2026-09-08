import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:discover/core/theme/app_theme.dart';
import 'package:discover/features/bootstrap/bootstrap.dart';
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

  // L'UI est montée tout de suite : init natives et appels API sont joués par
  // BootstrapGate, derrière un loader, et une panne devient un écran d'erreur
  // au lieu d'un démarrage avorté.
  runApp(
    BootstrapGate(
      builder: (showOnboarding, isGuest) => DiscoverApp(
        showOnboarding: showOnboarding,
        isGuest:        isGuest,
      ),
    ),
  );
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
