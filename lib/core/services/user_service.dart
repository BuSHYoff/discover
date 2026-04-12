import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:discover/features/journey/widgets/journey_progress.dart';

// ─────────────────────────────────────────────────────────────────────────────
// USER SERVICE — gère le document utilisateur dans Firestore (collection users)
// ─────────────────────────────────────────────────────────────────────────────

class UserService {
  static final _db = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  // ── Profil utilisateur ────────────────────────────────────────────────────

  /// Crée ou met à jour le document utilisateur après la fin de l'onboarding.
  static Future<void> saveUser({
    required String username,
    required String hobbyRelation,
    required List<String> universes,
    required String timePerWeek,
    required String budget,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final createdAt = user.metadata.creationTime;

    await _userDoc(user.uid).set(
      {
        'uid':      user.uid,
        'username': username,
        'email':    user.email ?? '',
        'preferences': {
          'hobbyRelation': hobbyRelation,
          'universes':     universes,
          'timePerWeek':   timePerWeek,
          'budget':        budget,
        },
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Met à jour uniquement le username.
  static Future<void> updateUsername(String username) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _userDoc(user.uid).set(
      {'username': username, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// Met à jour la couleur de profil (hex string).
  static Future<void> updateProfileColor(String colorHex) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _userDoc(user.uid).set(
      {'profileColor': colorHex, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// Charge la couleur de profil depuis Firestore. Retourne null si absente.
  static Future<String?> loadProfileColor() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final snap = await _userDoc(user.uid).get();
      return snap.data()?['profileColor'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Charge username + profileColor en un seul read Firestore.
  /// Retourne une map avec les clés 'username' et 'profileColor' (nullable).
  static Future<({String? username, String? profileColor})> loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return (username: null, profileColor: null);

    try {
      final snap = await _userDoc(user.uid).get();
      final data = snap.data();
      return (
        username:     data?['username']     as String?,
        profileColor: data?['profileColor'] as String?,
      );
    } catch (_) {
      return (username: null, profileColor: null);
    }
  }

  // ── Passions / Journey ────────────────────────────────────────────────────

  /// Sauvegarde l'état d'une passion dans `users/{uid}.passions.{passionId}`.
  /// Visible directement dans le document utilisateur Firestore.
  /// Fire-and-forget.
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String status;
    if (currentStep < 0) {
      status = 'not_started';
    } else if (globalPercent >= 1.0) {
      status = 'completed';
    } else {
      status = 'in_progress';
    }

    final passionData = <String, dynamic>{
      'passionId':   passionId,
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
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'completed') {
      passionData['completedAt'] = FieldValue.serverTimestamp();
    }

    // Dot notation → met à jour uniquement cette passion dans la map,
    // sans écraser les autres entrées du champ `passions`.
    _userDoc(user.uid)
        .update({'passions.$passionId': passionData})
        .catchError((_) {
          // Document pas encore créé (onboarding pas terminé) → set avec merge
          _userDoc(user.uid).set(
            {'passions': {passionId: passionData}},
            SetOptions(merge: true),
          ).catchError((e) {
            if (kDebugMode) debugPrint('[UserService] syncPassion error: $e');
          });
        });
  }

  /// Charge les passions depuis Firestore et restaure chaque JourneyProgress
  /// en local (SharedPreferences). Appelé à la reconnexion.
  static Future<void> loadAndRestorePassions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await _userDoc(user.uid).get();
      if (!snap.exists) return;

      final data = snap.data();
      final passions = data?['passions'] as Map<String, dynamic>?;
      if (passions == null || passions.isEmpty) return;

      for (final entry in passions.entries) {
        final passionId = entry.key;
        final raw = entry.value as Map<String, dynamic>?;
        if (raw == null) continue;

        final progress = JourneyProgress.of(passionId);
        await progress.restoreFromMap(raw);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[UserService] loadAndRestorePassions error: $e');
    }
  }
}
