import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:serverpod/serverpod.dart';

const jwtSecret = 'super-secret-key-change-me';

/// Demo credential store — swap for a real user repository in production.
const users = {
  'alice': 'password123',
  'bob': 'qwerty',
};

/// Custom [AuthenticationHandler] that validates JWT Bearer tokens.
///
/// Serverpod calls this handler for every request that carries an auth key.
/// The key arrives already unwrapped (stripped of the "Bearer " prefix).
Future<AuthenticationInfo?> jwtAuthHandler(
  Session session,
  String token,
) async {
  try {
    final jwt = JWT.verify(token, SecretKey(jwtSecret));
    final payload = jwt.payload as Map<String, dynamic>;
    final username = payload['sub'] as String?;
    if (username == null || !users.containsKey(username)) return null;
    return AuthenticationInfo(username, <Scope>{}, authId: token);
  } catch (_) {
    return null;
  }
}
