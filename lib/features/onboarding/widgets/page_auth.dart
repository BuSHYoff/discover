import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:discover/core/services/auth_service.dart';
import 'package:discover/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PAGE AUTH  —  étape 4 de l'onboarding
// Google Sign-In + formulaire email/mot de passe directement visibles.
// Si l'utilisateur est déjà connecté Firebase, la page avance automatiquement.
// ─────────────────────────────────────────────────────────────────────────────

class PageAuth extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  const PageAuth({super.key, required this.onAuthSuccess});

  @override
  State<PageAuth> createState() => _PageAuthState();
}

class _PageAuthState extends State<PageAuth> {
  bool _isSignUp = true;
  bool _loadingGoogle = false;
  bool _loadingEmail  = false;
  String? _error;

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  bool get _loading => _loadingGoogle || _loadingEmail;

  @override
  void initState() {
    super.initState();
    if (AuthService.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onAuthSuccess();
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Handlers ────────────────────────────────────────────────────────────────

  Future<void> _handleGoogle() async {
    setState(() { _loadingGoogle = true; _error = null; });
    try {
      final cred = await AuthService.signInWithGoogle();
      if (cred != null && mounted) widget.onAuthSuccess();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e.code));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
    }
  }

  Future<void> _handleEmail() async {
    final email = _emailCtrl.text.trim();
    final pw    = _passwordCtrl.text;
    if (email.isEmpty || pw.isEmpty) {
      setState(() => _error = 'Remplis tous les champs.');
      return;
    }
    setState(() { _loadingEmail = true; _error = null; });
    try {
      if (_isSignUp) {
        await AuthService.registerWithEmail(email, pw);
      } else {
        await AuthService.signInWithEmail(email, pw);
      }
      if (mounted) widget.onAuthSuccess();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _loadingEmail = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':     return 'Email ou mot de passe incorrect.';
      case 'wrong-password':         return 'Mot de passe incorrect.';
      case 'email-already-in-use':   return 'Cet email est déjà utilisé.';
      case 'weak-password':          return 'Mot de passe trop faible (6 caractères min.).';
      case 'invalid-email':          return 'Adresse email invalide.';
      case 'network-request-failed': return 'Vérifie ta connexion internet.';
      case 'too-many-requests':      return 'Trop de tentatives. Réessaie plus tard.';
      default:                       return 'Une erreur est survenue ($code).';
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Titre ─────────────────────────────────────────────────────────────
          Text.rich(
            TextSpan(
              style: GoogleFonts.firaSansCondensed(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                height: 1.05,
              ),
              children: [
                const TextSpan(text: 'Rejoins\nl\'aventure'),
                TextSpan(text: '.', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Crée ton compte pour sauvegarder\nton parcours et tes découvertes.',
            style: GoogleFonts.firaSansCondensed(
              fontSize: 15,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // ── Google ────────────────────────────────────────────────────────────
          _SocialButton(
            onTap: _loading ? null : _handleGoogle,
            icon: _loadingGoogle
                ? SizedBox(
                    width: 17, height: 17,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Theme.of(context).colorScheme.primary),
                  )
                : const _GoogleIcon(),
            label: 'Continuer avec Google',
          ),

          // ── Séparateur ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(children: [
              Expanded(child: Divider(color: AppColors.ink.withValues(alpha: 0.08))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('ou', style: GoogleFonts.firaSansCondensed(
                  fontSize: 13, color: AppColors.inkFaint,
                )),
              ),
              Expanded(child: Divider(color: AppColors.ink.withValues(alpha: 0.08))),
            ]),
          ),

          // ── Toggle Créer / Se connecter ───────────────────────────────────────
          Row(children: [
            _TabToggle(
              label: 'Créer un compte',
              active: _isSignUp,
              onTap: () => setState(() { _isSignUp = true; _error = null; }),
            ),
            const SizedBox(width: 24),
            _TabToggle(
              label: 'Se connecter',
              active: !_isSignUp,
              onTap: () => setState(() { _isSignUp = false; _error = null; }),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Champs email / mot de passe ───────────────────────────────────────
          _AuthTextField(
            controller: _emailCtrl,
            hint: 'Adresse email',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            controller: _passwordCtrl,
            hint: 'Mot de passe',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: AppColors.inkSoft,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),

          // ── Erreur ────────────────────────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorBox(message: _error!),
          ],
          const SizedBox(height: 20),

          // ── Bouton soumettre ──────────────────────────────────────────────────
          GestureDetector(
            onTap: _loading ? null : _handleEmail,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 54,
              decoration: BoxDecoration(
                color: _loading
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: _loadingEmail
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isSignUp ? 'Créer mon compte' : 'Me connecter',
                      style: GoogleFonts.firaSansCondensed(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSANTS LOCAUX
// ─────────────────────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget icon;
  final String label;

  const _SocialButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.1)),
          ),
          child: Row(children: [
            const SizedBox(width: 16),
            SizedBox(width: 24, child: Center(child: icon)),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.firaSansCondensed(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 40),
          ]),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: GoogleFonts.firaSansCondensed(fontSize: 15, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.firaSansCondensed(
              fontSize: 15, color: AppColors.inkFaint),
          prefixIcon: Icon(icon, size: 18, color: AppColors.inkSoft),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _TabToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabToggle({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.firaSansCondensed(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.ink : AppColors.inkFaint,
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    print('Error: $message');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: GoogleFonts.firaSansCondensed(
                  fontSize: 12, color: AppColors.error)),
        ),
      ]),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/google_logo.svg',
      width: 20,
      height: 20,
    );
  }
}
