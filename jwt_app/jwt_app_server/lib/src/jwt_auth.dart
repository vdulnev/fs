import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:serverpod/serverpod.dart';

// ── Secrets ─────────────────────────────────────────────────────────────────
// Use separate secrets so a leaked access token cannot be used to mint
// refresh tokens, and vice-versa.
const _accessSecret = 'super-secret-access-key-change-me';
const _refreshSecret = 'super-secret-refresh-key-change-me';

// ── Token durations ──────────────────────────────────────────────────────────
const accessTokenDuration = Duration(minutes: 15);
const refreshTokenDuration = Duration(days: 7);

// ── Credential store ─────────────────────────────────────────────────────────
/// Demo credential store — swap for a real user repository in production.
const users = {
  'alice': 'password123',
  'bob': 'qwerty',
};

// ── Token helpers ────────────────────────────────────────────────────────────

/// Signs and returns a new **access** token for [username].
String signAccessToken(String username) => JWT({
      'sub': username,
      'type': 'access',
      'iat': _nowEpoch(),
    }).sign(SecretKey(_accessSecret), expiresIn: accessTokenDuration);

/// Signs and returns a new **refresh** token for [username].
String signRefreshToken(String username) => JWT({
      'sub': username,
      'type': 'refresh',
      'iat': _nowEpoch(),
    }).sign(SecretKey(_refreshSecret), expiresIn: refreshTokenDuration);

/// Verifies a refresh token and returns the username it was issued for,
/// or `null` if the token is invalid, expired, or not a refresh token.
String? verifyRefreshToken(String token) {
  try {
    final jwt = JWT.verify(token, SecretKey(_refreshSecret));
    final payload = jwt.payload as Map<String, dynamic>;
    if (payload['type'] != 'refresh') return null;
    final username = payload['sub'] as String?;
    if (username == null || !users.containsKey(username)) return null;
    return username;
  } catch (_) {
    return null;
  }
}

// ── Serverpod auth handler ───────────────────────────────────────────────────

/// Custom [AuthenticationHandler] that validates **access** tokens only.
///
/// Serverpod calls this for every request that carries an auth key.
/// The key arrives already unwrapped (the "Bearer " prefix is stripped by the
/// framework before this handler is invoked).
Future<AuthenticationInfo?> jwtAuthHandler(
  Session session,
  String token,
) async {
  try {
    final jwt = JWT.verify(token, SecretKey(_accessSecret));
    final payload = jwt.payload as Map<String, dynamic>;
    // Refuse refresh tokens masquerading as access tokens.
    if (payload['type'] == 'refresh') return null;
    final username = payload['sub'] as String?;
    if (username == null || !users.containsKey(username)) return null;
    return AuthenticationInfo(username, <Scope>{}, authId: token);
  } catch (_) {
    return null;
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

int _nowEpoch() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
