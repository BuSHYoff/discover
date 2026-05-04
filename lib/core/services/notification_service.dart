import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId    = 'discover_reminders';
  static const _channelName  = 'Rappels Discover';
  static const _channelDesc  = 'Rappels hebdomadaires pour tes passions';
  static const _prefPermAsked       = 'notif_permission_asked';
  static const _prefReminderPrefix  = 'reminder_';
  static const _prefRemindersData   = 'reminders_data_';
  // Slots par rappel : 10 occurrences max (pour intervalles custom)
  static const _slotsPerReminder    = 10;
  static const _maxReminders        = 8;

  // ── Initialisation ──────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    // Affiche les notifications même quand l'app est en foreground (iOS)
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _initialized = true;
  }

  // ── Permissions ─────────────────────────────────────────────────────────────

  /// Retourne true si les permissions sont accordées.
  static Future<bool> isPermissionGranted() async {
    if (Platform.isIOS) {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await impl?.checkPermissions();
      return granted?.isEnabled ?? false;
    } else {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await impl?.areNotificationsEnabled();
      return granted ?? false;
    }
  }

  /// Demande la permission. Retourne true si accordée.
  static Future<bool> requestPermission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefPermAsked, true);

    if (Platform.isIOS) {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await impl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    } else {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await impl?.requestNotificationsPermission();
      return granted ?? false;
    }
  }

  /// True si on n'a jamais demandé la permission.
  static Future<bool> hasNeverAskedPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_prefPermAsked) ?? false);
  }

  // ── Rappels personnalisés ───────────────────────────────────────────────────

  /// ID de notification pour un rappel donné (passionId × reminderIdx × occurrenceIdx).
  static int _notifId(String passionId, int reminderIdx, int occurrenceIdx) =>
      ((passionId.hashCode.abs() % 200000) * _maxReminders * _slotsPerReminder +
          reminderIdx * _slotsPerReminder +
          occurrenceIdx)
          .abs() %
      2000000000;

  /// Retourne true si au moins un rappel est actif pour cette passion.
  static Future<bool> isReminderEnabled(String passionId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefReminderPrefix$passionId') ?? false;
  }

  /// Charge les rappels sauvegardés pour une passion.
  /// Retourne une liste de maps `{hour, minute, intervalDays}`.
  static Future<List<Map<String, dynamic>>> getReminders(String passionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefRemindersData$passionId');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Planifie tous les rappels pour une passion.
  /// Chaque rappel = `{hour, minute, intervalDays}`.
  static Future<void> scheduleReminders({
    required String passionId,
    required String passionName,
    required List<Map<String, dynamic>> reminders,
  }) async {
    await initialize();

    // Annuler les anciens
    await cancelReminder(passionId);

    if (reminders.isEmpty) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId, _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    for (int i = 0; i < reminders.length && i < _maxReminders; i++) {
      final r            = reminders[i];
      final hour         = r['hour']         as int;
      final minute       = r['minute']       as int;
      final intervalDays = (r['intervalDays'] as int?) ?? 1;

      final now = tz.TZDateTime.now(tz.local);
      // Prochaine occurrence de l'heure choisie
      var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

      if (intervalDays == 1) {
        // Tous les jours à la même heure → infiniment récurrent
        await _plugin.zonedSchedule(
          _notifId(passionId, i, 0),
          'C\'est l\'heure pour $passionName !',
          'Maintiens ta pratique — chaque jour compte.',
          next,
          notifDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else if (intervalDays == 7) {
        // Toutes les semaines le même jour/heure → infiniment récurrent
        await _plugin.zonedSchedule(
          _notifId(passionId, i, 0),
          'C\'est l\'heure pour $passionName !',
          'Ta pratique hebdomadaire t\'attend.',
          next,
          notifDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else {
        // Intervalle custom : on planifie les N prochaines occurrences
        var scheduled = next;
        for (int j = 0; j < _slotsPerReminder; j++) {
          await _plugin.zonedSchedule(
            _notifId(passionId, i, j),
            'C\'est l\'heure pour $passionName !',
            'Maintiens ta pratique régulièrement.',
            scheduled,
            notifDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          scheduled = scheduled.add(Duration(days: intervalDays));
        }
      }
    }

    // Sauvegarder
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefReminderPrefix$passionId', true);
    await prefs.setString('$_prefRemindersData$passionId', jsonEncode(reminders));
  }

  /// Annule tous les rappels d'une passion et réinitialise le flag.
  static Future<void> cancelReminder(String passionId) async {
    // Annuler tous les IDs possibles pour cette passion
    for (int i = 0; i < _maxReminders; i++) {
      for (int j = 0; j < _slotsPerReminder; j++) {
        await _plugin.cancel(_notifId(passionId, i, j));
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefReminderPrefix$passionId', false);
    await prefs.remove('$_prefRemindersData$passionId');
  }

  // ── FCM Token (pour notifications push) ────────────────────────────────────

  /// Sauvegarde le token dans Firestore users/{uid} avec timestamp.
  static Future<void> _writeTokenToFirestore(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('[FCM] _writeTokenToFirestore — pas d\'user connecté, abandon.');
      return;
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    debugPrint('[FCM] Token enregistré dans Firestore pour uid=$uid');
  }

  /// Retourne true si le token Firestore a plus de 7 jours (ou absent).
  static Future<bool> _shouldRefreshToken(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final updatedAt = doc.data()?['fcmTokenUpdatedAt'] as Timestamp?;
      if (updatedAt == null) return true;
      final age = DateTime.now().difference(updatedAt.toDate());
      return age.inDays >= 7;
    } catch (_) {
      return true; // En cas d'erreur, on rafraîchit quand même
    }
  }

  /// Appelé au démarrage (main.dart) — installe uniquement l'écouteur
  /// onTokenRefresh, SANS demander la permission. Pas de popup système.
  static void setupTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) async {
        debugPrint('[FCM] Token rafraîchi automatiquement : $newToken');
        try {
          await _writeTokenToFirestore(newToken);
        } catch (e) {
          debugPrint('[FCM] Erreur mise à jour token rafraîchi : $e');
        }
      },
      onError: (error) {
        debugPrint('[FCM] Erreur onTokenRefresh : $error');
      },
    );
    debugPrint('[FCM] Écouteur onTokenRefresh installé.');
  }

  /// Appelé depuis la HomeScreen après onboarding/connexion.
  /// Demande la permission iOS puis sauvegarde le token si > 7 jours.
  static Future<void> initFcmToken() async {
    try {
      debugPrint('[FCM] initFcmToken() — début');

      // 1. Demande la permission (popup iOS — à appeler depuis HomeScreen)
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      debugPrint('[FCM] Permission : ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] Permission refusée.');
        return;
      }

      // 2. Vérifie si le token a besoin d'être rafraîchi (> 7 jours)
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final needsRefresh = await _shouldRefreshToken(uid);
      if (!needsRefresh) {
        debugPrint('[FCM] Token encore valide (< 7 jours) — skip.');
        return;
      }
      debugPrint('[FCM] Token absent ou > 7 jours — mise à jour.');

      // 3. Attendre le token APNs (iOS uniquement)
      if (Platform.isIOS) {
        String? apnsToken;
        int attempts = 0;
        while (apnsToken == null && attempts < 10) {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken == null) {
            debugPrint('[FCM] APNs pas encore prêt (${attempts + 1}/10)...');
            await Future.delayed(const Duration(seconds: 1));
          }
          attempts++;
        }
        if (apnsToken == null) {
          debugPrint('[FCM] APNs null — vérifier Push Notifications capability dans Xcode.');
          return;
        }
        debugPrint('[FCM] APNs token reçu.');
      }

      // 4. Récupération + sauvegarde du token FCM
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('[FCM] Token FCM : $token');
      if (token == null) return;
      await _writeTokenToFirestore(token);

      debugPrint('[FCM] initFcmToken() — succès.');
    } catch (e, stack) {
      debugPrint('[FCM] Erreur : $e');
      debugPrint('[FCM] Stack : $stack');
    }
  }

  static Future<void> saveFcmToken() => initFcmToken();
}
