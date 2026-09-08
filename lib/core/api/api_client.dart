import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Wrapper HTTP partagé pour toute l'app — UN SEUL point d'entrée vers le
/// backend NestJS. Attache automatiquement le Firebase ID Token en Bearer.
///
/// Configuration de l'URL : `--dart-define=API_URL=https://...`
/// Défaut : URL Cloud Run de prod.
class ApiClient {
  ApiClient._();

  /// URL de base injectée à la compilation. Le défaut pointe sur l'instance
  /// Cloud Run de prod ; pour le dev, lancer avec :
  ///   flutter run --dart-define=API_URL=http://localhost:3000
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://discover-backend-6giut7xaeq-ew.a.run.app',
  );

  static final _http = http.Client();

  // ── Politique de retry ─────────────────────────────────────────────────────

  /// Nombre total de tentatives (1 appel initial + 3 retries).
  static const int _maxAttempts = 4;

  /// Attente avant le 1er retry, doublée à chaque tentative suivante.
  static const Duration _initialBackoff = Duration(milliseconds: 500);

  /// Plafond par tentative — évite qu'une connexion suspendue bloque le
  /// démarrage de l'app indéfiniment.
  static const Duration _requestTimeout = Duration(seconds: 20);

  // ── Helpers d'auth ─────────────────────────────────────────────────────────

  /// Récupère le Firebase ID Token courant, ou null si pas connecté.
  /// `forceRefresh: true` pour invalider le cache (utile après changement de
  /// custom claims, ex: passage admin).
  static Future<String?> _idToken({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }

  // ── Méthodes publiques ─────────────────────────────────────────────────────

  /// GET `path` (+ query params). Retourne le JSON décodé en `T`.
  ///
  /// Si `auth: false`, n'attache pas de Bearer (utile pour les routes
  /// publiques même si le backend ignore le token d'un guest).
  static Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send<T>('GET', path, query: query, auth: auth);

  static Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send<T>('POST', path, body: body, query: query, auth: auth);

  static Future<T> put<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send<T>('PUT', path, body: body, query: query, auth: auth);

  static Future<T> patch<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send<T>('PATCH', path, body: body, query: query, auth: auth);

  static Future<T> delete<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send<T>('DELETE', path, body: body, query: query, auth: auth);

  // ── Upload multipart (image post) ──────────────────────────────────────────

  /// Upload multipart pour `POST /passions/:id/posts/upload`.
  /// Le backend reçoit `title`, `caption`, `image` (file) et renvoie le Post créé.
  static Future<Map<String, dynamic>> uploadPostImage({
    required String passionId,
    required File imageFile,
    required String title,
    required String caption,
  }) async {
    final url = _buildUri('/passions/$passionId/posts/upload');
    final req = http.MultipartRequest('POST', url)
      ..fields['title']   = title
      ..fields['caption'] = caption
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final token = await _idToken();
    if (token != null) {
      req.headers['Authorization'] = 'Bearer $token';
    }

    final streamed = await _http.send(req);
    final body     = await streamed.stream.bytesToString();
    return _parseJsonResponse<Map<String, dynamic>>(streamed.statusCode, body);
  }

  // ── Implémentation interne ─────────────────────────────────────────────────

  static Uri _buildUri(String path, [Map<String, dynamic>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final qs = <String, String>{};
    if (query != null) {
      query.forEach((k, v) {
        if (v != null) qs[k] = v.toString();
      });
    }
    return Uri.parse('$baseUrl$cleanPath').replace(
      queryParameters: qs.isEmpty ? null : qs,
    );
  }

  /// Rejoue [_sendOnce] tant que l'erreur est transitoire, avec un backoff
  /// exponentiel (0,5 s → 1 s → 2 s → 4 s, soit ~7,5 s d'attente cumulée).
  ///
  /// Motivé par Cloud Run en scale-to-zero : après une période d'inactivité,
  /// la première requête peut être rejetée (429 « no available instance ») ou
  /// mise en attente le temps qu'une instance démarre. Sans retry, ce réveil
  /// remontait jusqu'à l'UI sous forme d'erreur.
  static Future<T> _send<T>(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    var delay = _initialBackoff;

    for (var attempt = 1; ; attempt++) {
      try {
        return await _sendOnce<T>(method, path,
            body: body, query: query, auth: auth);
      } catch (e) {
        if (attempt >= _maxAttempts || !_isTransient(e)) rethrow;
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }

  /// Vrai si l'erreur vaut la peine d'être retentée : indisponibilité
  /// temporaire côté serveur, ou coupure réseau passagère côté client.
  static bool _isTransient(Object e) {
    if (e is ApiException) {
      // 429 : instance indisponible · 502/503/504 : backend en cours de réveil.
      return e.status == 429 ||
             e.status == 502 ||
             e.status == 503 ||
             e.status == 504;
    }
    return e is SocketException ||
           e is TimeoutException ||
           e is http.ClientException;
  }

  static Future<T> _sendOnce<T>(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    final uri = _buildUri(path, query);

    // On ne déclare un Content-Type qu'en présence d'un body : Fastify rejette
    // un body vide associé à `application/json`. Pour les DELETE / POST sans
    // body, on omet le header → le serveur traite comme un payload vide.
    final encoded = body == null ? null : jsonEncode(body);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (encoded != null) 'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await _idToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    final Future<http.Response> pending;
    switch (method) {
      case 'GET':    pending = _http.get   (uri, headers: headers);                    break;
      case 'DELETE': pending = _http.delete(uri, headers: headers, body: encoded);     break;
      case 'POST':   pending = _http.post  (uri, headers: headers, body: encoded);     break;
      case 'PUT':    pending = _http.put   (uri, headers: headers, body: encoded);     break;
      case 'PATCH':  pending = _http.patch (uri, headers: headers, body: encoded);     break;
      default:
        throw ArgumentError('Méthode HTTP non supportée : $method');
    }

    final res = await pending.timeout(_requestTimeout);

    return _parseJsonResponse<T>(res.statusCode, res.body);
  }

  static T _parseJsonResponse<T>(int statusCode, String body) {
    // 204 No Content — pas de body
    if (statusCode == 204 || body.isEmpty) {
      if (T == dynamic || _isNullable<T>()) return null as T;
      // Si on attendait un T concret mais le serveur n'a rien renvoyé,
      // on retourne quand même null (les appelants gèrent).
      return null as T;
    }

    final dynamic payload = _safeJsonDecode(body);

    if (statusCode < 200 || statusCode >= 300) {
      final msg = (payload is Map && payload['message'] != null)
          ? payload['message'].toString()
          : 'HTTP $statusCode';
      throw ApiException(statusCode, msg, payload);
    }

    return payload as T;
  }

  static dynamic _safeJsonDecode(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return s; // payload non-JSON → on remonte la string brute (ex: HTML 502)
    }
  }

  static bool _isNullable<T>() => null is T;
}
