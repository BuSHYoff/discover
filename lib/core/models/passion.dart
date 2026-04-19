import 'package:cloud_firestore/cloud_firestore.dart';

// ─── MODÈLE PASSION ──────────────────────────────────────────────────────────

class Passion {
  final String  id;
  final String  name;
  final String  category;
  final List<String> tags;
  final String  country;
  final String  description;
  final String  tagline;
  final String  imageUrl;
  final String? subreddit; // ex: "baduk" pour r/baduk

  const Passion({
    required this.id,
    required this.name,
    required this.category,
    required this.tags,
    required this.country,
    required this.description,
    required this.tagline,
    this.imageUrl = '',
    this.subreddit,
  });

  factory Passion.fromJson(Map<String, dynamic> j) => Passion(
    id:          j['id']          as String,
    name:        j['name']        as String? ?? '',
    category:    j['category']    as String? ?? '',
    tags:        List<String>.from(j['tags'] ?? []),
    country:     j['country']     as String? ?? '',
    description: j['description'] as String? ?? '',
    tagline:     j['tagline']     as String? ?? '',
    imageUrl:    j['imageUrl']    as String? ?? '',
    subreddit:   j['subreddit']   as String?,
  );
}

// ─── PASSION STEP ─────────────────────────────────────────────────────────────

class PassionStep {
  final int    step;
  final String title;
  final String details;

  const PassionStep({
    required this.step,
    required this.title,
    required this.details,
  });

  factory PassionStep.fromJson(Map<String, dynamic> j) => PassionStep(
    step:    (j['step'] as num?)?.toInt() ?? 0,
    title:   j['title']   as String? ?? '',
    details: j['details'] as String? ?? '',
  );
}

// ─── CONTENU IA — aligné sur passions.json ────────────────────────────────────

class AIContent {
  final String id;
  final String tagline;
  final List<PassionStep> steps;
  final List<AIMaterial> materials;
  final String totalBudget;
  final List<String> tips;
  final List<AIResource> resources;

  const AIContent({
    required this.id,
    required this.tagline,
    required this.steps,
    required this.materials,
    required this.totalBudget,
    required this.tips,
    required this.resources,
  });

  // ─── Convenience getters ───────────────────────────────────────────────────
  List<String> get thisWeek => steps.map((s) => s.title).toList();
  List<AIObjective> get objectives30Days =>
      tips.asMap().entries
          .map((e) => AIObjective(
                week:      'Tip ${e.key + 1}',
                objective: e.value,
              ))
          .toList();

  factory AIContent.fromJson(Map<String, dynamic> j) => AIContent(
    id:          j['id']           as String,
    tagline:     j['tagline']      as String? ?? '',
    steps:       (j['steps']       as List? ?? [])
        .map((e) => PassionStep.fromJson(e as Map<String, dynamic>))
        .toList(),
    materials:   (j['materials']   as List? ?? [])
        .map((e) => AIMaterial.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalBudget: j['total_budget'] as String? ?? '',
    tips:        List<String>.from(j['tips'] ?? []),
    resources:   (j['ressources']  as List? ?? [])
        .map((e) => AIResource.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

// ─── MATÉRIEL ─────────────────────────────────────────────────────────────────

class AIMaterial {
  final String name;
  final String price;
  final String note;

  const AIMaterial({
    required this.name,
    required this.price,
    required this.note,
  });

  factory AIMaterial.fromJson(Map<String, dynamic> j) => AIMaterial(
    name:  j['name']  as String? ?? '',
    price: j['price'] as String? ?? '',
    note:  j['note']  as String? ?? '',
  );
}

// ─── OBJECTIF (compat journey) ────────────────────────────────────────────────

class AIObjective {
  final String week;
  final String objective;

  const AIObjective({required this.week, required this.objective});
}

// ─── RESSOURCE ────────────────────────────────────────────────────────────────

class AIResource {
  final String type;
  final String title;
  final String url;
  final String verification;
  final String detail;

  const AIResource({
    required this.type,
    required this.title,
    required this.url,
    required this.verification,
    required this.detail,
  });

  factory AIResource.fromJson(Map<String, dynamic> j) => AIResource(
    type:         j['type']         as String? ?? '',
    title:        j['titre']        as String? ?? j['title'] as String? ?? '',
    url:          j['url']          as String? ?? '',
    verification: j['verification'] as String? ?? '',
    detail:       j['detail']       as String? ?? '',
  );
}

// ─── PASSION REPOSITORY ───────────────────────────────────────────────────────

class PassionRepository {
  static final PassionRepository _instance = PassionRepository._();
  static PassionRepository get instance => _instance;
  PassionRepository._();

  List<Passion> _passions = [];
  Map<String, AIContent> _aiCache = {};
  bool _loaded = false;

  List<Passion> get passions => _passions;
  Map<String, AIContent> get aiCache => _aiCache;

  Future<void> load() async {
    if (_loaded) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('passions')
        .get();
    _passions = [];
    _aiCache  = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      _passions.add(Passion.fromJson(data));
      _aiCache[doc.id] = AIContent.fromJson(data);
    }
    _loaded = true;
  }
}

// ─── ACCESSEUR GLOBAL ─────────────────────────────────────────────────────────

List<Passion> get allPassions => PassionRepository.instance.passions;

const List<String> categories = [
  'Art & Créativité', 'Corps & Mouvement', 'Gastronomie',
  'Nature & Exploration', 'Musique & Son', 'Sciences & Tech', 'Bien-être & Esprit',
];
