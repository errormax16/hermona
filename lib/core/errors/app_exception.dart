// ─────────────────────────────────────────────────────────────────────────────
// AppException – exceptions typées pour toute l'application
// ─────────────────────────────────────────────────────────────────────────────
class AppException implements Exception {
  final String message;
  final int? statusCode;
  const AppException(this.message, {this.statusCode});

  @override
  String toString() => statusCode != null 
      ? 'Erreur: $message (code: $statusCode)' 
      : 'Erreur: $message';
}

class NetworkException extends AppException {
  const NetworkException([String msg = 'Erreur réseau']) : super(msg);
}

class AuthException extends AppException {
  const AuthException(String msg) : super(msg);
}

class ApiException extends AppException {
  const ApiException(String msg, {int? statusCode})
      : super(msg, statusCode: statusCode);
}
