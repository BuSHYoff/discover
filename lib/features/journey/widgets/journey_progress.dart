import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show IconData, Icons;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:discover/core/services/user_service.dart';

class JourneyProgress extends ChangeNotifier {

  static final Map<String, JourneyProgress> _registry = {};

  static JourneyProgress of(String passionId) {
    final existing = _registry[passionId];
    if (existing != null && !existing._isDisposed) return existing;
    final fresh = JourneyProgress._(passionId);
    _registry[passionId] = fresh;
    return fresh;
  }

  /// Vide le cache statique des instances (à appeler lors de la déconnexion).
  static void resetAll() {
    _registry.clear();
  }

  final String _passionId;
  bool _isDisposed = false;

  JourneyProgress._(this._passionId) {
    _loadFromDisk();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // ── État ──────────────────────────────────────────────────────────────────
  int thisWeekDone       = 0; int thisWeekTotal  = 0;
  int materialsDone      = 0; int materialsTotal = 0;

  int currentStep = -1;

  List<bool> thisWeekChecked = [];
  List<bool> materialsChecked = [];

  // ── NOUVEAU : timestamps de déblocage par étape journalière ───────────────
  // dailyUnlocks[i] = ms epoch quand l'étape i est devenue/devient disponible
  List<int> dailyUnlocks = [];

  // ── NOUVEAU : vidéos YouTube regardées (3 slots) ──────────────────────────
  List<bool> videosWatched = [false, false, false];

  // ── NOUVEAU : timestamp de complétion finale ──────────────────────────────
  int? completedAtMs;

  // ── NOUVEAU : sous-tâches cochées par jour (matrice 2D) ───────────────────
  // subtasksChecked[dayIdx][subtaskIdx] = true si la sous-tâche est complétée
  List<List<bool>> subtasksChecked = [];

  // ── NOUVEAU : sessions focus terminées par jour ───────────────────────────
  List<bool> focusCompleted = [];

  bool _loaded = false;
  bool get isLoaded => _loaded;
  bool get started  => currentStep >= 0;
  bool get completed => completedAtMs != null;

  // ── Noms & icônes (3 étapes : Matériel, Cette semaine, Partager)
  static const stepNames = [
    'Matériel', 'Cette semaine', 'Partager',
  ];
  static const stepIconData = <IconData>[
    Icons.shopping_bag_outlined,
    Icons.rocket_launch_outlined,
    Icons.diversity_3_rounded,
  ];

  // ── Données par étape ─────────────────────────────────────────────────────
  List<JourneyStepData> get steps => [
    JourneyStepData(name: stepNames[0], iconData: stepIconData[0],
        done: materialsDone, total: materialsTotal),
    JourneyStepData(name: stepNames[1], iconData: stepIconData[1],
        done: thisWeekDone, total: thisWeekTotal),
    JourneyStepData(name: stepNames[2], iconData: stepIconData[2],
        done: currentStep >= 2 ? 1 : 0, total: 1),
  ];

  // ── Progression globale ───────────────────────────────────────────────────
  double get globalPercent {
    final done  = materialsDone + thisWeekDone + (currentStep >= 2 ? 1 : 0);
    final total = materialsTotal + thisWeekTotal + 1;
    if (total == 0) return 0;
    return (done / total).clamp(0.0, 1.0);
  }

  int get globalPercentInt => (globalPercent * 100).round();

  // ── Persistence ───────────────────────────────────────────────────────────

  String get _prefKey => 'journey_$_passionId';

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_prefKey);
      if (raw != null) {
        final map = json.decode(raw) as Map<String, dynamic>;
        currentStep      = (map['currentStep'] as int?) ?? -1;
        thisWeekTotal    = (map['csTotal']     as int?) ?? 0;
        materialsTotal   = (map['matTotal']    as int?) ?? 0;
        thisWeekDone     = (map['csDone']      as int?) ?? 0;
        materialsDone    = (map['matDone']     as int?) ?? 0;

        thisWeekChecked  = _decodeBools(map['csChecked'],  thisWeekTotal);
        materialsChecked = _decodeBools(map['matChecked'], materialsTotal);
        dailyUnlocks     = _decodeInts(map['dailyUnlocks'], thisWeekTotal);
        videosWatched    = _decodeBools(map['videosWatched'], 3);
        completedAtMs    = map['completedAtMs'] as int?;
        subtasksChecked  = _decodeBoolMatrix(map['subtasksChecked']);
        focusCompleted   = _decodeBools(map['focusCompleted'], thisWeekTotal);
      }
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, json.encode({
        'currentStep'  : currentStep,
        'csTotal'      : thisWeekTotal,
        'matTotal'     : materialsTotal,
        'csDone'       : thisWeekDone,
        'matDone'      : materialsDone,
        'csChecked'    : thisWeekChecked,
        'matChecked'   : materialsChecked,
        'dailyUnlocks'    : dailyUnlocks,
        'videosWatched'   : videosWatched,
        'completedAtMs'   : completedAtMs,
        'subtasksChecked' : subtasksChecked,
        'focusCompleted'  : focusCompleted,
      }));
    } catch (_) {}
  }

  static List<List<bool>> _decodeBoolMatrix(dynamic raw) {
    if (raw == null) return [];
    try {
      final outer = raw as List;
      return outer.map((row) {
        if (row is! List) return <bool>[];
        return row.cast<bool>();
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static List<int> _decodeInts(dynamic raw, int expectedLength) {
    if (raw == null) return List.filled(expectedLength, 0);
    try {
      final list = (raw as List).map((e) => (e as num).toInt()).toList();
      if (list.length == expectedLength) return list;
      // Padding ou troncature
      final out = List<int>.filled(expectedLength, 0);
      for (int i = 0; i < list.length && i < expectedLength; i++) out[i] = list[i];
      return out;
    } catch (_) {
      return List.filled(expectedLength, 0);
    }
  }

  /// Appeler explicitement à la fermeture du JourneyScreen.
  void syncToFirestore() {
    UserService.syncPassion(
      passionId:        _passionId,
      currentStep:      currentStep,
      materialsTotal:   materialsTotal,
      materialsDone:    materialsDone,
      materialsChecked: materialsChecked,
      thisWeekTotal:    thisWeekTotal,
      thisWeekDone:     thisWeekDone,
      thisWeekChecked:  thisWeekChecked,
      globalPercent:    globalPercent,
    );
  }

  static List<bool> _decodeBools(dynamic raw, int expectedLength) {
    if (raw == null) return List.filled(expectedLength, false);
    try {
      final list = (raw as List).cast<bool>();
      if (list.length == expectedLength) return list;
      return List.filled(expectedLength, false);
    } catch (_) {
      return List.filled(expectedLength, false);
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  void initTotals({
    required int thisWeek,
    required int materials,
  }) {
    if (thisWeekTotal != thisWeek) {
      thisWeekTotal   = thisWeek;
      thisWeekChecked = List.filled(thisWeek, false);
      thisWeekDone    = 0;
      dailyUnlocks    = List.filled(thisWeek, 0);
      // Le 1er jour est toujours débloqué dès que matériel est cochable
      if (thisWeek > 0) dailyUnlocks[0] = DateTime.now().millisecondsSinceEpoch;
    } else if (dailyUnlocks.length != thisWeek) {
      // Migration : ancien JourneyProgress sans dailyUnlocks
      dailyUnlocks = List.filled(thisWeek, 0);
      if (thisWeek > 0) dailyUnlocks[0] = DateTime.now().millisecondsSinceEpoch;
    }
    if (materialsTotal != materials) {
      materialsTotal   = materials;
      materialsChecked = List.filled(materials, false);
      materialsDone    = 0;
    }
    if (videosWatched.length != 3) {
      videosWatched = List.filled(3, false);
    }
    _saveToDisk();
    notifyListeners();
  }

  /// Marque l'étape journalière `index` comme complétée et programme le
  /// déblocage de la suivante 24h plus tard (ou immédiat via skip).
  void completeDailyStep(int index, {bool skipTo24h = false}) {
    if (index < 0 || index >= thisWeekTotal) return;
    if (index < thisWeekChecked.length) thisWeekChecked[index] = true;
    thisWeekDone = thisWeekChecked.where((v) => v).length;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final next  = index + 1;
    if (next < thisWeekTotal) {
      final delayMs = skipTo24h
          ? nowMs
          : nowMs + const Duration(hours: 24).inMilliseconds;
      // Ne raccourcit jamais un déblocage plus précoce déjà programmé
      if (dailyUnlocks[next] == 0 || delayMs < dailyUnlocks[next]) {
        dailyUnlocks[next] = delayMs;
      }
    }
    _saveToDisk();
    notifyListeners();
  }

  /// Force le déblocage immédiat de l'étape `index` (skip token).
  void unlockDailyStepNow(int index) {
    if (index < 0 || index >= dailyUnlocks.length) return;
    dailyUnlocks[index] = DateTime.now().millisecondsSinceEpoch;
    _saveToDisk();
    notifyListeners();
  }

  /// True si l'étape journalière `index` est disponible (timestamp ≤ now).
  bool isDailyUnlocked(int index) {
    if (index < 0 || index >= dailyUnlocks.length) return false;
    final ts = dailyUnlocks[index];
    if (ts == 0) return false;
    return DateTime.now().millisecondsSinceEpoch >= ts;
  }

  /// Millisecondes restantes avant déblocage (0 si déjà dispo).
  int dailyRemainingMs(int index) {
    if (index < 0 || index >= dailyUnlocks.length) return 0;
    final ts = dailyUnlocks[index];
    if (ts == 0) return -1; // pas encore programmé
    final delta = ts - DateTime.now().millisecondsSinceEpoch;
    return delta > 0 ? delta : 0;
  }

  void markVideoWatched(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= videosWatched.length) return;
    if (videosWatched[slotIndex]) return;
    videosWatched[slotIndex] = true;
    _saveToDisk();
    notifyListeners();
  }

  bool isVideoWatched(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= videosWatched.length) return false;
    return videosWatched[slotIndex];
  }

  void markCompleted() {
    completedAtMs = DateTime.now().millisecondsSinceEpoch;
    _saveToDisk();
    notifyListeners();
  }

  // ── Sous-tâches & focus session ─────────────────────────────────────────────

  /// Initialise la matrice subtasksChecked d'après le nombre de sous-tâches par jour.
  void initSubtasks(List<int> subtaskCountsPerDay) {
    if (subtasksChecked.length != subtaskCountsPerDay.length) {
      subtasksChecked = List.generate(
        subtaskCountsPerDay.length,
        (i) => List.filled(subtaskCountsPerDay[i], false),
      );
    } else {
      // Vérifie que chaque ligne a la bonne taille (sinon migration douce)
      for (int i = 0; i < subtaskCountsPerDay.length; i++) {
        final expected = subtaskCountsPerDay[i];
        if (subtasksChecked[i].length != expected) {
          final old = subtasksChecked[i];
          subtasksChecked[i] = List<bool>.generate(
            expected,
            (j) => j < old.length ? old[j] : false,
          );
        }
      }
    }
    if (focusCompleted.length != subtaskCountsPerDay.length) {
      final old = focusCompleted;
      focusCompleted = List<bool>.generate(
        subtaskCountsPerDay.length,
        (i) => i < old.length ? old[i] : false,
      );
    }
    _saveToDisk();
  }

  /// Marque la sous-tâche `subtaskIdx` du jour `dayIdx` comme cochée.
  void checkSubtask(int dayIdx, int subtaskIdx) {
    if (dayIdx < 0 || dayIdx >= subtasksChecked.length) return;
    if (subtaskIdx < 0 || subtaskIdx >= subtasksChecked[dayIdx].length) return;
    if (subtasksChecked[dayIdx][subtaskIdx]) return;
    subtasksChecked[dayIdx][subtaskIdx] = true;
    _saveToDisk();
    notifyListeners();
  }

  bool isSubtaskChecked(int dayIdx, int subtaskIdx) {
    if (dayIdx < 0 || dayIdx >= subtasksChecked.length) return false;
    if (subtaskIdx < 0 || subtaskIdx >= subtasksChecked[dayIdx].length) return false;
    return subtasksChecked[dayIdx][subtaskIdx];
  }

  /// True si toutes les sous-tâches du jour sont cochées.
  bool isDayFullyChecked(int dayIdx) {
    if (dayIdx < 0 || dayIdx >= subtasksChecked.length) return false;
    final row = subtasksChecked[dayIdx];
    return row.isNotEmpty && row.every((v) => v);
  }

  void markFocusCompleted(int dayIdx) {
    if (dayIdx < 0 || dayIdx >= focusCompleted.length) return;
    if (focusCompleted[dayIdx]) return;
    focusCompleted[dayIdx] = true;
    _saveToDisk();
    notifyListeners();
  }

  bool isFocusCompleted(int dayIdx) {
    if (dayIdx < 0 || dayIdx >= focusCompleted.length) return false;
    return focusCompleted[dayIdx];
  }

  /// Réinitialise toutes les sous-tâches et le statut de complétion d'un jour.
  void resetDay(int dayIdx) {
    if (dayIdx < 0 || dayIdx >= subtasksChecked.length) return;
    subtasksChecked[dayIdx] = List.filled(subtasksChecked[dayIdx].length, false);
    if (dayIdx < focusCompleted.length)  focusCompleted[dayIdx]  = false;
    if (dayIdx < thisWeekChecked.length) thisWeekChecked[dayIdx] = false;
    thisWeekDone = thisWeekChecked.where((v) => v).length;
    _saveToDisk();
    notifyListeners();
  }

  void updateStep(int step) {
    currentStep = step;
    _saveToDisk();
    notifyListeners();
  }

  void updateCounts({
    required List<bool> thisWeek,
    required List<bool> materials,
  }) {
    thisWeekChecked  = List.of(thisWeek);
    materialsChecked = List.of(materials);

    thisWeekDone  = thisWeek.where((v) => v).length;
    materialsDone = materials.where((v) => v).length;

    _saveToDisk();
    notifyListeners();
  }

  /// Restaure l'état depuis le payload backend et persiste en local.
  ///
  /// `dailyUnlocks` est lu tel quel — c'est le serveur qui en est l'autorité.
  /// Si l'utilisateur arrive sur un nouveau device, il récupère les vrais
  /// timestamps d'unlock posés au moment de chaque complétion.
  Future<void> restoreFromMap(Map<String, dynamic> raw) async {
    final prog = raw['progress'] as Map<String, dynamic>? ?? {};

    currentStep    = (raw['currentStep'] as int?) ?? -1;
    materialsTotal = (prog['materialsTotal'] as int?) ?? 0;
    materialsDone  = (prog['materialsDone']  as int?) ?? 0;
    thisWeekTotal  = (prog['thisWeekTotal']  as int?) ?? 0;
    thisWeekDone   = (prog['thisWeekDone']   as int?) ?? 0;

    materialsChecked = _decodeBools(prog['materialsChecked'], materialsTotal);
    thisWeekChecked  = _decodeBools(prog['thisWeekChecked'],  thisWeekTotal);
    dailyUnlocks     = _decodeInts(prog['dailyUnlocks'], thisWeekTotal);

    await _saveToDisk();
    notifyListeners();
  }

  Future<void> reset() async {
    currentStep         = -1;
    thisWeekDone    = 0; thisWeekTotal   = 0;
    materialsDone        = 0; materialsTotal       = 0;
    thisWeekChecked = [];
    materialsChecked     = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    notifyListeners();
  }
}

// ─── DATA CLASS ───────────────────────────────────────────────────────────────

class JourneyStepData {
  final String   name;
  final IconData iconData;
  final int done;
  final int total;

  const JourneyStepData({
    required this.name,
    required this.iconData,
    required this.done,
    required this.total,
  });

  double get percent    => total == 0 ? 0 : (done / total).clamp(0.0, 1.0);
  bool   get isComplete => total > 0 && done >= total;
  bool   get isStarted  => done > 0;
}