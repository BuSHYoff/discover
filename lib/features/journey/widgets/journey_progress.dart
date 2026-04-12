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
  int thisWeekDone  = 0; int thisWeekTotal  = 0;
  int materialsDone      = 0; int materialsTotal      = 0;

  int currentStep = -1;

  List<bool> thisWeekChecked = [];
  List<bool> materialsChecked     = [];

  bool _loaded = false;
  bool get isLoaded => _loaded;
  bool get started  => currentStep >= 0;

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
        currentStep        = (map['currentStep'] as int?) ?? -1;
        thisWeekTotal  = (map['csTotal']     as int?) ?? 0;
        materialsTotal      = (map['matTotal']    as int?) ?? 0;
        thisWeekDone   = (map['csDone']      as int?) ?? 0;
        materialsDone       = (map['matDone']     as int?) ?? 0;

        thisWeekChecked = _decodeBools(map['csChecked'],  thisWeekTotal);
        materialsChecked     = _decodeBools(map['matChecked'], materialsTotal);
      }
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, json.encode({
        'currentStep': currentStep,
        'csTotal'    : thisWeekTotal,
        'matTotal'   : materialsTotal,
        'csDone'     : thisWeekDone,
        'matDone'    : materialsDone,
        'csChecked'  : thisWeekChecked,
        'matChecked' : materialsChecked,
      }));
    } catch (_) {}
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
    }
    if (materialsTotal != materials) {
      materialsTotal   = materials;
      materialsChecked = List.filled(materials, false);
      materialsDone    = 0;
    }
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

  /// Restaure l'état depuis une map Firestore et persiste en local.
  Future<void> restoreFromMap(Map<String, dynamic> raw) async {
    final prog = raw['progress'] as Map<String, dynamic>? ?? {};

    currentStep    = (raw['currentStep'] as int?) ?? -1;
    materialsTotal = (prog['materialsTotal'] as int?) ?? 0;
    materialsDone  = (prog['materialsDone']  as int?) ?? 0;
    thisWeekTotal  = (prog['thisWeekTotal']  as int?) ?? 0;
    thisWeekDone   = (prog['thisWeekDone']   as int?) ?? 0;

    materialsChecked = _decodeBools(prog['materialsChecked'], materialsTotal);
    thisWeekChecked  = _decodeBools(prog['thisWeekChecked'],  thisWeekTotal);

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