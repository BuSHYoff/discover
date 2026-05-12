// ─────────────────────────────────────────────────────────────────────────────
// MODÈLES PASSION — alignés sur backend/src/passions/entities/passion.entity.ts
// Aucune dépendance Firestore : tout vient de l'API via http JSON.
//
// Le backend split la lecture en 2 routes :
//   - GET /passions             → Passion[] (light + tips/ressources/shorts)
//   - GET /passions/:id         → Passion (même shape)
//   - GET /passions/:id/journey → PassionJourney (steps/materials/topVideos)
//
// Côté Flutter on miroir cette séparation. Les écrans qui veulent un objet
// unifié passent par AIContentProvider qui merge les 2 sources en mémoire.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:discover/core/services/passions_service.dart';

// Re-export pour ne pas casser les écrans qui importaient `passion.dart` et
// utilisaient `AIContentProvider` (anciennement déclaré ici).
export 'package:discover/core/services/passions_service.dart' show AIContentProvider;

/// Passion light + browsing : tout ce qui est consommable AVANT que l'user
/// engage l'activité. Récupérée via `/passions` et `/passions/:id`.
class Passion {
  final String  id;
  final String  name;
  final String  category;
  final String  country;
  final String  description;
  final String  tagline;
  final String  imageUrl;
  final String? subreddit;

  // Contenu "browsing" — visible dans le DetailScreen avant engagement.
  final List<String>      tips;
  final List<AIResource>  resources;
  final List<AIVideo>     shorts;

  const Passion({
    required this.id,
    required this.name,
    required this.category,
    required this.country,
    required this.description,
    required this.tagline,
    this.imageUrl  = '',
    this.subreddit,
    this.tips      = const [],
    this.resources = const [],
    this.shorts    = const [],
  });

  factory Passion.fromJson(Map<String, dynamic> j) => Passion(
    id:          j['id']          as String,
    name:        j['name']        as String? ?? '',
    category:    j['category']    as String? ?? '',
    country:     j['country']     as String? ?? '',
    description: j['description'] as String? ?? '',
    tagline:     j['tagline']     as String? ?? '',
    imageUrl:    j['imageUrl']    as String? ?? '',
    subreddit:   j['subreddit']   as String?,
    tips:        List<String>.from(j['tips'] as List? ?? const []),
    resources:  (j['ressources'] as List? ?? const [])
        .map((e) => AIResource.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    shorts:     _parseVideos(j['shorts']),
  );

  static List<AIVideo> _parseVideos(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => AIVideo.fromJson(Map<String, dynamic>.from(e)))
        .where((v) => v.url.isNotEmpty)
        .toList();
  }
}

/// Contenu pédagogique d'une passion — chargé uniquement quand l'user clique
/// "Commencer l'activité". Mirroir de backend/src/passions/entities Passion-
/// Journey.
class PassionJourney {
  final String passionId;
  final List<PassionStep> steps;
  final List<AIMaterial>  materials;
  final List<AIVideo>     topVideos;

  const PassionJourney({
    required this.passionId,
    this.steps     = const [],
    this.materials = const [],
    this.topVideos = const [],
  });

  factory PassionJourney.fromJson(Map<String, dynamic> j) => PassionJourney(
    passionId: j['passionId'] as String? ?? '',
    steps: (j['steps'] as List? ?? const [])
        .map((e) => PassionStep.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    materials: (j['materials'] as List? ?? const [])
        .map((e) => AIMaterial.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    topVideos: (j['topVideos'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => AIVideo.fromJson(Map<String, dynamic>.from(e)))
        .where((v) => v.url.isNotEmpty)
        .toList(),
  );
}

// ─── PASSION STEP ────────────────────────────────────────────────────────────

class PassionStep {
  final String title;
  final String details;
  final List<PassionSubtask> subtasks;

  /// Compat : le backend n'envoie pas de `step` numérique (l'ordre du tableau
  /// suffit). On retourne l'index pour les écrans qui en ont besoin via
  /// `.asMap().entries.map(...)`. Champ conservé pour compat ascendante.
  final int step;

  const PassionStep({
    required this.title,
    required this.details,
    this.subtasks = const [],
    this.step = 0,
  });

  factory PassionStep.fromJson(Map<String, dynamic> j) => PassionStep(
    title:   j['title']   as String? ?? '',
    details: j['details'] as String? ?? '',
    step:    (j['step'] as num?)?.toInt() ?? 0,
    subtasks: (j['subtasks'] as List? ?? const [])
        .map(PassionSubtask.fromAny)
        .where((s) => s.title.isNotEmpty)
        .toList(),
  );
}

// ─── PASSION SUBTASK ─────────────────────────────────────────────────────────

class PassionSubtask {
  final String title;
  final String howTo;
  final String videoUrl;

  const PassionSubtask({
    required this.title,
    this.howTo    = '',
    this.videoUrl = '',
  });

  /// Accepte un Map (format actuel) ou un String (legacy).
  factory PassionSubtask.fromAny(dynamic raw) {
    if (raw is String) return PassionSubtask(title: raw.trim());
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      return PassionSubtask(
        title:    (m['title']    as String?)?.trim() ?? '',
        howTo:    (m['howTo']    as String?)?.trim() ?? '',
        videoUrl: (m['videoUrl'] as String?)?.trim() ?? '',
      );
    }
    return const PassionSubtask(title: '');
  }
}

// ─── AI VIDEO ────────────────────────────────────────────────────────────────

class AIVideo {
  final String url;
  final String title;
  final String channel;
  final String thumbnail;

  const AIVideo({
    required this.url,
    this.title     = '',
    this.channel   = '',
    this.thumbnail = '',
  });

  /// Fallback thumbnail si la BDD n'en a pas (vidéo saisie main).
  String get effectiveThumbnail {
    if (thumbnail.isNotEmpty) return thumbnail;
    final id = _extractYoutubeId(url);
    return id == null ? '' : 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
  }

  factory AIVideo.fromJson(Map<String, dynamic> j) => AIVideo(
    url:       (j['url']       as String?)?.trim() ?? '',
    title:     (j['title']     as String?)?.trim() ?? '',
    channel:   (j['channel']   as String?)?.trim() ?? '',
    thumbnail: (j['thumbnail'] as String?)?.trim() ?? '',
  );
}

String? _extractYoutubeId(String url) {
  final u = url.trim();
  if (u.isEmpty) return null;
  final regexes = [
    RegExp(r'(?:youtube\.com\/(?:watch\?v=|shorts\/|embed\/|v\/))([\w-]{11})'),
    RegExp(r'youtu\.be\/([\w-]{11})'),
  ];
  for (final r in regexes) {
    final m = r.firstMatch(u);
    if (m != null) return m.group(1);
  }
  return null;
}

// ─── AI CONTENT (vue dérivée Passion + PassionJourney) ───────────────────────
//
// AIContent agrège les 2 sources pour les écrans qui veulent tout. Construit
// par AIContentProvider via un merge à la lecture (cf. passions_service.dart).

class AIContent {
  final String id;
  final String tagline;
  final List<PassionStep> steps;
  final List<AIMaterial>  materials;
  final List<String>      tips;
  final List<AIResource>  resources;
  final List<AIVideo>     topVideos;
  final List<AIVideo>     shorts;

  const AIContent({
    required this.id,
    required this.tagline,
    required this.steps,
    required this.materials,
    required this.tips,
    required this.resources,
    this.topVideos = const [],
    this.shorts    = const [],
  });

  // Convenience getters utilisés par les écrans
  List<String> get thisWeek => steps.map((s) => s.title).toList();
  List<AIObjective> get objectives30Days =>
      tips.asMap().entries
          .map((e) => AIObjective(week: 'Tip ${e.key + 1}', objective: e.value))
          .toList();
}

// ─── MATÉRIEL ────────────────────────────────────────────────────────────────

class AIMaterial {
  final String name;
  final String note;

  const AIMaterial({
    required this.name,
    required this.note,
  });

  factory AIMaterial.fromJson(Map<String, dynamic> j) => AIMaterial(
    name: j['name'] as String? ?? '',
    note: j['note'] as String? ?? '',
  );
}

// ─── OBJECTIF (compat journey) ───────────────────────────────────────────────

class AIObjective {
  final String week;
  final String objective;

  const AIObjective({required this.week, required this.objective});
}

// ─── RESSOURCE ───────────────────────────────────────────────────────────────

class AIResource {
  final String type;
  final String title;
  final String url;
  final String detail;

  const AIResource({
    required this.type,
    required this.title,
    required this.url,
    required this.detail,
  });

  factory AIResource.fromJson(Map<String, dynamic> j) => AIResource(
    type:   j['type']   as String? ?? '',
    title:  j['titre']  as String? ?? j['title'] as String? ?? '',
    url:    j['url']    as String? ?? '',
    detail: j['detail'] as String? ?? '',
  );
}

// ─── ACCESSEUR GLOBAL (catalogue chargé une fois au boot) ────────────────────

List<Passion> get allPassions => PassionsService.cached;

const List<String> categories = [
  'Art & Créativité', 'Corps & Mouvement',
  'Nature & Exploration', 'Musique & Son', 'Sciences & Tech', 'Bien-être & Esprit',
];
