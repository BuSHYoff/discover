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
  static const _prefPermAsked = 'notif_permission_asked';
  static const _prefReminderPrefix = 'reminder_';

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

  // ── Rappels hebdomadaires ───────────────────────────────────────────────────

  /// Retourne true si le rappel pour cette passion est activé.
  static Future<bool> isReminderEnabled(String passionId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefReminderPrefix$passionId') ?? false;
  }

  /// Active le rappel hebdomadaire pour une passion.
  /// Notif tous les samedis à 10h00.
  static Future<void> scheduleWeeklyReminder({
    required String passionId,
    required String passionName,
  }) async {
    await initialize();
    final notifId = passionId.hashCode.abs() % 100000;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Prochain samedi à 10h00
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 10, 0);
    // Avance jusqu'au prochain samedi
    while (scheduled.weekday != DateTime.saturday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      notifId,
      'C\'est le moment pour $passionName !',
      'Tu avais commencé ta progression — reprenons là où tu t\'es arrêté.',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefReminderPrefix$passionId', true);
  }

  /// Désactive le rappel pour une passion.
  static Future<void> cancelReminder(String passionId) async {
    final notifId = passionId.hashCode.abs() % 100000;
    await _plugin.cancel(notifId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefReminderPrefix$passionId', false);
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
