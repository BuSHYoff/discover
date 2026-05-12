import 'package:discover/core/models/passion.dart';
import 'package:discover/core/models/trending.dart';
import 'package:discover/core/services/trending_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WEEKLY PASSION SERVICE — wrapper compat
// L'ancienne API (`fetch()`) renvoyait `WeeklyPassionData`. Le backend expose
// désormais le même endpoint mais via TrendingService. On garde un alias pour
// ne pas casser les écrans qui appellent encore `WeeklyPassionService.fetch()`.
// ─────────────────────────────────────────────────────────────────────────────

class WeeklyPassionData {
  final Passion passion;
  final String  description;

  const WeeklyPassionData({required this.passion, required this.description});

  factory WeeklyPassionData.fromWeekly(WeeklyPassion w) =>
      WeeklyPassionData(passion: w.passion, description: w.description);
}

class WeeklyPassionService {
  WeeklyPassionService._();

  static Future<WeeklyPassionData?> fetch() async {
    final w = await TrendingService.fetchWeeklyPassion();
    if (w == null || w.description.isEmpty) return null;
    return WeeklyPassionData.fromWeekly(w);
  }
}
