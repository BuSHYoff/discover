import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:discover/core/api/api_client.dart';
import 'package:discover/core/api/api_exception.dart';
import 'package:discover/core/models/app_user.dart';
import 'package:discover/features/journey/widgets/journey_progress.dart';

// ─────────────────────────────────────────────────────────────────────────────
// USER SERVICE
// Tous les reads/writes utilisateur passent par l'API NestJS.
// Routes principales :
//   GET    /users/me
//   PATCH  /users/me
//   DELETE /users/me
//   PUT    /users/me/passions/:passionId
//   GET    /users/me/passions
// ─────────────────────────────────────────────────────────────────────────────

class UserService {
  UserService._();

  // ── Profil utilisateur ────────────────────────────────────────────────────

  /// Crée ou met à jour le document utilisateur après l'onboarding.
  /// Le backend fait l'upsert sur `users/{uid}` à partir du JWT.
  static Future<void> saveUser({
    required String username,
    required String hobbyRelation,
    required List<String> universes,
    required String timePerWeek,
    required String budget,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await ApiClient.patch<dynamic>('/users/me', body: {
        'username': username,
        'preferences': {
          'hobbyRelation': hobbyRelation,
          'universes':     universes,
          'timePerWeek':   timePerWeek,
          'budget':        budget,
        },
      });
    } on ApiException catch (e) {
      if (kDebugMode) debugPrint('[UserService] saveUser: $e');
      rethrow;
    }
  }

  // ── Debounce + dedup pour les édits de profil "rapides" ───────────────────
  //
  // L'utilisateur peut taper plein de caractères dans le champ username ou
  // faire glisser un picker de couleur — chaque event déclencherait un
  // PATCH sinon. On bufférise pendant 800 ms : seul le dernier état est
  // envoyé. En plus, on dedup : si la valeur n'a pas changé depuis le
  // dernier push réussi, on skip le PATCH.

  static const Duration _profileDebounce = Duration(milliseconds: 800);

  static Timer?  _usernameTimer;
  static String? _usernamePending;
  static String? _usernameLastSent;

  static Timer?  _colorTimer;
  static String? _colorPending;
  static String? _colorLastSent;

  /// Met à jour le username — debounced 800 ms, dedup automatique.
  /// Appelable à chaque keystroke sans crainte de spam backend.
  static void updateUsername(String username) {
    if (FirebaseAuth.instance.currentUser == null) return;
    _usernamePending = username;
    _usernameTimer?.cancel();
    _usernameTimer = Timer(_profileDebounce, _flushUsername);
  }

  /// Met à jour la couleur de profil — debounced 800 ms, dedup automatique.
  static void updateProfileColor(String colorHex) {
    if (FirebaseAuth.instance.currentUser == null) return;
    _colorPending = colorHex;
    _colorTimer?.cancel();
    _colorTimer = Timer(_profileDebounce, _flushColor);
  }

  /// Force l'envoi immédiat des modifs en attente (à appeler par exemple
  /// quand on quitte l'écran profil) — évite de perdre le dernier état.
  static Future<void> flushProfileEdits() async {
    await Future.wait([_flushUsername(), _flushColor()]);
  }

  static Future<void> _flushUsername() async {
    _usernameTimer?.cancel();
    final value = _usernamePending;
    if (value == null || value == _usernameLastSent) return;
    try {
      await ApiClient.patch<dynamic>('/users/me', body: {'username': value});
      _usernameLastSent = value;
    } catch (e) {
      if (kDebugMode) debugPrint('[UserService] updateUsername: $e');
    }
  }

  static Future<void> _flushColor() async {
    _colorTimer?.cancel();
    final value = _colorPending;
    if (value == null || value == _colorLastSent) return;
    try {
      await ApiClient.patch<dynamic>('/users/me', body: {'profileColor': value});
      _colorLastSent = value;
    } catch (e) {
      if (kDebugMode) debugPrint('[UserService] updateProfileColor: $e');
    }
  }

  /// Charge la couleur de profil.
  static Future<String?> loadProfileColor() async {
    final me = await _loadMeOrNull();
    return me?.profileColor;
  }

  /// Charge username + profileColor en un seul appel.
  static Future<({String? username, String? profileColor})> loadUserProfile() async {
    final me = await _loadMeOrNull();
    return (
      username:     me?.username,
      profileColor: me?.profileColor,
    );
  }

  /// Récupère le user complet (null si pas connecté ou 401).
  static Future<AppUser?> loadMe() => _loadMeOrNull();

  static Future<AppUser?> _loadMeOrNull() async {
    if (FirebaseAuth.instance.currentUser == null) return null;
    try {
      final json = await ApiClient.get<Map<String, dynamic>>('/users/me');
      return AppUser.fromJson(json);
    } catch (e) {
      if (kDebugMode) debugPrint('[UserService] loadMe: $e');
      return null;
    }
  }

  // ── Passions / Journey ────────────────────────────────────────────────────

  /// Pousse l'état d'une passion vers le backend (`PUT /users/me/passions/:id`).
  /// Fire-and-forget — on n'attend pas la réponse.
  static void syncPassion({
    required String passionId,
    required int    currentStep,
    required int    materialsTotal,
    required int    materialsDone,
    required List<bool> materialsChecked,
    required int    thisWeekTotal,
    required int    thisWeekDone,
    required List<bool> thisWeekChecked,
    required double globalPercent,
  }) {
    if (FirebaseAuth.instance.currentUser == null) return;

    final String status;
    if (currentStep < 0) {
      status = 'not_started';
    } else if (globalPercent >= 1.0) {
      status = 'completed';
    } else {
      status = 'in_progress';
    }

    final body = <String, dynamic>{
      'status':      status,
      'currentStep': currentStep,
      'progress': {
        'globalPercent':    (globalPercent * 100).round(),
        'materialsDone':    materialsDone,
        'materialsTotal':   materialsTotal,
        'materialsChecked': materialsChecked,
        'thisWeekDone':     thisWeekDone,
        'thisWeekTotal':    thisWeekTotal,
        'thisWeekChecked':  thisWeekChecked,
      },
    };

    ApiClient.put<dynamic>('/users/me/passions/$passionId', body: body)
        .catchError((e) {
      if (kDebugMode) debugPrint('[UserService] syncPassion: $e');
      return null;
    });
  }

  /// Supprime le compte côté backend (cascade : posts, comments, doc user).
  /// Puis supprime le compte Firebase Auth.
  static Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Supprime le doc user (le backend gère le cascade)
    try {
      await ApiClient.delete<dynamic>('/users/me');
    } catch (e) {
      if (kDebugMode) debugPrint('[UserService] deleteAccount API: $e');
    }

    // 2. Supprime le compte Firebase Auth
    try {
      await user.delete();
    } catch (e) {
      if (kDebugMode) debugPrint('[UserService] deleteAccount Auth: $e');
    }
  }

  /// Restaure la progression locale (JourneyProgress en SharedPreferences) à
  /// partir des passions du user récupérées via l'API.
  /// Appelé après login.
  static Future<void> loadAndRestorePassions() async {
    final me = await _loadMeOrNull();
    if (me == null || me.passions.isEmpty) return;

    for (final entry in me.passions.entries) {
      final passionId = entry.key;
      final p         = entry.value;
      final progress  = JourneyProgress.of(passionId);

      // Re-projete le UserPassionProgress vers le format attendu par
      // JourneyProgress.restoreFromMap (compat ascendante).
      await progress.restoreFromMap({
        'currentStep': p.currentStep,
        'progress':    p.progress.toJson(),
      });
    }
  }
}
