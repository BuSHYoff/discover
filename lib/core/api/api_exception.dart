/// Exception typée renvoyée par l'API NestJS (status non-2xx).
///
/// Le wrapper [ApiClient] la lève automatiquement à partir du JSON d'erreur
/// retourné par NestJS, qui suit le format :
///   { "statusCode": 404, "message": "Passion inexistante", "error": "Not Found" }
class ApiException implements Exception {
  final int    status;
  final String message;
  final Object? payload;

  const ApiException(this.status, this.message, [this.payload]);

  bool get isUnauthorized => status == 401;
  bool get isForbidden    => status == 403;
  bool get isNotFound     => status == 404;
  bool get isThrottled    => status == 429;
  bool get isServerError  => status >= 500;

  @override
  String toString() => 'ApiException($status): $message';
}
