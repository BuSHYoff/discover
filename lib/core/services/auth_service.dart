import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AUTH SERVICE
// Connexion Google + Email/Mot de passe via Firebase Auth.
//
// ⚠️  GoogleSignIn.instance.initialize() doit être appelé dans main()
//    après Firebase.initializeApp().
// ─────────────────────────────────────────────────────────────────────────────

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Accesseurs ──────────────────────────────────────────────────────────────

  /// Utilisateur Firebase actuellement connecté, ou null.
  static User? get currentUser => _auth.currentUser;

  /// Stream des changements d'état d'authentification.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Retourne l'ID Token actuel (utilisé pour les Bearer côté API). Null si
  /// pas connecté. Forcer refresh si on vient de changer des custom claims.
  static Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  }

  // ── Google ──────────────────────────────────────────────────────────────────

  static Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount account =
        await GoogleSignIn.instance.authenticate();

    final String? idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return await _auth.signInWithCredential(credential);
  }

  // ── Apple ───────────────────────────────────────────────────────────────────

  static Future<UserCredential?> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    return await _auth.signInWithCredential(oauthCredential);
  }

  // ── Email / Mot de passe ─────────────────────────────────────────────────────

  /// Connexion avec un compte existant.
  static Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Création d'un nouveau compte.
  static Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ── Déconnexion simple ───────────────────────────────────────────────────────

  static Future<void> signOut() async {
    await Future.wait([
      GoogleSignIn.instance.signOut(),
      _auth.signOut(),
    ]);
  }

  // ── Déconnexion complète — vide tout le stockage local ───────────────────────

  static Future<void> fullSignOut() async {
    // 1. Déconnecte Firebase + Google
    await Future.wait([
      GoogleSignIn.instance.signOut(),
      _auth.signOut(),
    ]);
    // 2. Efface toutes les SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
