import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:discover/core/api/api_client.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId    = 'discover_reminders';
  static const _channelName  = 'Rappels Discover';
  static const _channelDesc  = 'Rappels hebdomadaires pour tes passions';
  static const _prefPermAsked        = 'notif_permission_asked';
  static const _prefReminderPrefix   = 'reminder_';
  static const _prefRemindersData    = 'reminders_data_';
  static const _prefLastTokenSync    = 'fcm_last_token_sync'; // ISO 8601
  static const _slotsPerReminder     = 10;
  static const _maxReminders         = 8;

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

    // Affiche les notifications même en foreground (iOS)
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _initialized = true;
  }

  // ── Permissions ─────────────────────────────────────────────────────────────

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

  static Future<bool> hasNeverAskedPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_prefPermAsked) ?? false);
  }

  // ── Rappels personnalisés (locaux, SharedPreferences) ──────────────────────

  static int _notifId(String passionId, int reminderIdx, int occurrenceIdx) =>
      ((passionId.hashCode.abs() % 200000) * _maxReminders * _slotsPerReminder +
              reminderIdx * _slotsPerReminder +
              occurrenceIdx)
          .abs() %
      2000000000;

  static Future<bool> isReminderEnabled(String passionId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefReminderPrefix$passionId') ?? false;
  }

  static Future<List<Map<String, dynamic>>> getReminders(String passionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString('$_prefRemindersData$passionId');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> scheduleReminders({
    required String passionId,
    required String passionName,
    required List<Map<String, dynamic>> reminders,
  }) async {
    await initialize();
    await cancelReminder(passionId);
    if (reminders.isEmpty) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId, _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority:   Priority.defaultPriority,
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

      final now  = tz.TZDateTime.now(tz.local);
      var   next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

      if (intervalDays == 1) {
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefReminderPrefix$passionId', true);
    await prefs.setString('$_prefRemindersData$passionId', jsonEncode(reminders));
  }

  static Future<void> cancelReminder(String passionId) async {
    for (int i = 0; i < _maxReminders; i++) {
      for (int j = 0; j < _slotsPerReminder; j++) {
        await _plugin.cancel(_notifId(passionId, i, j));
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefReminderPrefix$passionId', false);
    await prefs.remove('$_prefRemindersData$passionId');
  }

  // ── FCM Token push (envoi vers backend) ────────────────────────────────────

  /// Pousse le token FCM vers `POST /users/me/fcm-token`.
  /// Le backend stocke le token dans Firestore. L'envoi de notifications push
  /// côté serveur n'est pas encore implémenté.
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      await ApiClient.post<dynamic>(
        '/users/me/fcm-token',
        body: {'token': token},
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLastTokenSync, DateTime.now().toIso8601String());
      if (kDebugMode) debugPrint('[FCM] Token poussé vers backend.');
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] Erreur push token : $e');
    }
  }

  /// Indique s'il faut rafraîchir le token (absent ou plus de 7 jours).
  static Future<bool> _shouldRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final last  = prefs.getString(_prefLastTokenSync);
    if (last == null) return true;
    final lastDate = DateTime.tryParse(last);
    if (lastDate == null) return true;
    return DateTime.now().difference(lastDate).inDays >= 7;
  }

  /// Installe l'écouteur de rotation de token au démarrage.
  /// Pas de popup permission — c'est `initFcmToken` qui s'en charge.
  static void setupTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) async {
        if (kDebugMode) debugPrint('[FCM] Token rafraîchi : $newToken');
        await _sendTokenToBackend(newToken);
      },
      onError: (e) {
        if (kDebugMode) debugPrint('[FCM] Erreur onTokenRefresh : $e');
      },
    );
  }

  /// À appeler après login. Demande la permission iOS puis pousse le token
  /// si nécessaire (absent ou > 7 jours).
  static Future<void> initFcmToken() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      if (FirebaseAuth.instance.currentUser == null) return;
      if (!await _shouldRefreshToken()) return;

      // iOS : attendre le token APNs
      if (Platform.isIOS) {
        String? apnsToken;
        int attempts = 0;
        while (apnsToken == null && attempts < 10) {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken == null) await Future.delayed(const Duration(seconds: 1));
          attempts++;
        }
        if (apnsToken == null) return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _sendTokenToBackend(token);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[FCM] Erreur : $e');
        debugPrint('[FCM] Stack : $stack');
      }
    }
  }

  /// Alias historique.
  static Future<void> saveFcmToken() => initFcmToken();

  /// Supprime le token côté backend (à la déconnexion).
  static Future<void> deleteFcmToken() async {
    try {
      await ApiClient.delete<dynamic>('/users/me/fcm-token');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefLastTokenSync);
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] Erreur suppression token : $e');
    }
  }
}
