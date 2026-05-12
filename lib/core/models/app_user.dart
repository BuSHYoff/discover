// ─────────────────────────────────────────────────────────────────────────────
// Modèles User — miroir de backend/src/users/entities/user.entity.ts
// Nommé "AppUser" pour ne pas entrer en conflit avec FirebaseAuth `User`.
// ─────────────────────────────────────────────────────────────────────────────

class UserPreferences {
  final String       hobbyRelation;
  final List<String> universes;
  final String       timePerWeek;
  final String       budget;

  const UserPreferences({
    required this.hobbyRelation,
    required this.universes,
    required this.timePerWeek,
    required this.budget,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> j) => UserPreferences(
    hobbyRelation: j['hobbyRelation'] as String? ?? '',
    universes:     List<String>.from(j['universes'] as List? ?? const []),
    timePerWeek:   j['timePerWeek']   as String? ?? '',
    budget:        j['budget']        as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'hobbyRelation': hobbyRelation,
    'universes':     universes,
    'timePerWeek':   timePerWeek,
    'budget':        budget,
  };
}

class UserStreak {
  final int     count;
  final String? lastActive; // YYYY-MM-DD

  const UserStreak({required this.count, this.lastActive});

  factory UserStreak.fromJson(Map<String, dynamic> j) => UserStreak(
    count:      (j['count'] as num?)?.toInt() ?? 0,
    lastActive: j['lastActive'] as String?,
  );
}

class PassionProgressBody {
  final int        globalPercent;
  final int        materialsDone;
  final int        materialsTotal;
  final List<bool> materialsChecked;
  final int        thisWeekDone;
  final int        thisWeekTotal;
  final List<bool> thisWeekChecked;
  /// Timestamps de déblocage par jour (epoch ms UTC). Géré par le serveur.
  final List<int>  dailyUnlocks;

  const PassionProgressBody({
    required this.globalPercent,
    required this.materialsDone,
    required this.materialsTotal,
    required this.materialsChecked,
    required this.thisWeekDone,
    required this.thisWeekTotal,
    required this.thisWeekChecked,
    this.dailyUnlocks = const [],
  });

  factory PassionProgressBody.fromJson(Map<String, dynamic> j) => PassionProgressBody(
    globalPercent:    (j['globalPercent']    as num?)?.toInt() ?? 0,
    materialsDone:    (j['materialsDone']    as num?)?.toInt() ?? 0,
    materialsTotal:   (j['materialsTotal']   as num?)?.toInt() ?? 0,
    materialsChecked: _boolList(j['materialsChecked']),
    thisWeekDone:     (j['thisWeekDone']     as num?)?.toInt() ?? 0,
    thisWeekTotal:    (j['thisWeekTotal']    as num?)?.toInt() ?? 0,
    thisWeekChecked:  _boolList(j['thisWeekChecked']),
    dailyUnlocks:     _intList(j['dailyUnlocks']),
  );

  Map<String, dynamic> toJson() => {
    'globalPercent':    globalPercent,
    'materialsDone':    materialsDone,
    'materialsTotal':   materialsTotal,
    'materialsChecked': materialsChecked,
    'thisWeekDone':     thisWeekDone,
    'thisWeekTotal':    thisWeekTotal,
    'thisWeekChecked':  thisWeekChecked,
    'dailyUnlocks':     dailyUnlocks,
  };
}

class UserPassionProgress {
  final String passionId;
  final String status; // not_started | in_progress | completed
  final int    currentStep;
  final PassionProgressBody progress;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  const UserPassionProgress({
    required this.passionId,
    required this.status,
    required this.currentStep,
    required this.progress,
    this.completedAt,
    this.updatedAt,
  });

  factory UserPassionProgress.fromJson(Map<String, dynamic> j) => UserPassionProgress(
    passionId:   j['passionId'] as String? ?? '',
    status:      j['status']    as String? ?? 'not_started',
    currentStep: (j['currentStep'] as num?)?.toInt() ?? -1,
    progress: PassionProgressBody.fromJson(
      Map<String, dynamic>.from(j['progress'] as Map? ?? const {}),
    ),
    completedAt: _parseDate(j['completedAt']),
    updatedAt:   _parseDate(j['updatedAt']),
  );

  Map<String, dynamic> toJson() => {
    'passionId':   passionId,
    'status':      status,
    'currentStep': currentStep,
    'progress':    progress.toJson(),
    if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    if (updatedAt   != null) 'updatedAt':   updatedAt!.toIso8601String(),
  };
}

class AppUser {
  final String  uid;
  final String  username;
  final String  email;
  final String? profileColor;
  final UserPreferences? preferences;
  final Map<String, UserPassionProgress> passions;
  final UserStreak? streak;
  final String?    fcmToken;
  final DateTime?  createdAt;
  final DateTime?  updatedAt;

  const AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.profileColor,
    this.preferences,
    this.passions = const {},
    this.streak,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) {
    final passionsRaw = j['passions'] as Map<String, dynamic>? ?? const {};
    final passions = <String, UserPassionProgress>{};
    passionsRaw.forEach((k, v) {
      if (v is Map) {
        passions[k] = UserPassionProgress.fromJson(Map<String, dynamic>.from(v));
      }
    });
    return AppUser(
      uid:          j['uid']          as String? ?? '',
      username:     j['username']     as String? ?? '',
      email:        j['email']        as String? ?? '',
      profileColor: j['profileColor'] as String?,
      preferences: j['preferences'] is Map
          ? UserPreferences.fromJson(Map<String, dynamic>.from(j['preferences'] as Map))
          : null,
      passions: passions,
      streak: j['streak'] is Map
          ? UserStreak.fromJson(Map<String, dynamic>.from(j['streak'] as Map))
          : null,
      fcmToken:  j['fcmToken']  as String?,
      createdAt: _parseDate(j['createdAt']),
      updatedAt: _parseDate(j['updatedAt']),
    );
  }
}

/// Page paginée d'users (admin).
class PaginatedUsers {
  final List<AppUser> items;
  final String?       nextCursor;

  const PaginatedUsers({required this.items, this.nextCursor});

  factory PaginatedUsers.fromJson(Map<String, dynamic> j) => PaginatedUsers(
    items: (j['items'] as List? ?? const [])
        .map((e) => AppUser.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    nextCursor: j['nextCursor'] as String?,
  );
}

DateTime? _parseDate(dynamic raw) {
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

List<bool> _boolList(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((e) => e == true).toList();
}

List<int> _intList(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((e) => (e is num) ? e.toInt() : 0).toList();
}
