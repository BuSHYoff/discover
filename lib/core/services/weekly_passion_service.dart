import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:discover/core/models/passion.dart';

// ─── Modèle ───────────────────────────────────────────────────────────────────

class WeeklyPassionData {
  final Passion passion;
  final String  description;

  const WeeklyPassionData({required this.passion, required this.description});
}

// ─── Service ──────────────────────────────────────────────────────────────────

class WeeklyPassionService {
  static final _db = FirebaseFirestore.instance;

  /// Lit app_config/weekly_passion.
  /// Retourne null si le document n'existe pas, si le passionId est invalide,
  /// ou en cas d'erreur Firestore → la card n'est pas affichée.
  static Future<WeeklyPassionData?> fetch() async {
    try {
      final snap = await _db
          .collection('app_config')
          .doc('weekly_passion')
          .get();

      if (!snap.exists) return null;

      final data        = snap.data();
      final passionId   = data?['passionId']   as String? ?? '';
      final description = data?['description'] as String? ?? '';

      final passion = PassionRepository.instance.passions
          .where((p) => p.id == passionId)
          .firstOrNull;

      if (passion == null || description.isEmpty) return null;

      return WeeklyPassionData(passion: passion, description: description);
    } catch (_) {
      return null;
    }
  }
}
