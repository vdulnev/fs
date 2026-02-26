import 'package:serverpod/serverpod.dart';

import 'generated/protocol.dart';
import 'jwt_auth.dart';

/// Exposes authentication operations.
///
/// Accessible from the client as `client.auth`.
class AuthEndpoint extends Endpoint {
  /// Validates [username]/[password] and returns an [AuthTokens] pair on
  /// success, or `null` if the credentials are invalid.
  ///
  /// The [AuthTokens.accessToken] is short-lived (15 min) and must be sent
  /// with every protected API call.  When it expires, use [refresh] to obtain
  /// a new one without asking the user to log in again.
  Future<AuthTokens?> login(
    Session session,
    String username,
    String password,
  ) async {
    if (users[username] != password) {
      session.log(
        'Failed login attempt for user: "$username"',
        level: LogLevel.info,
      );
      return null;
    }

    return AuthTokens(
      accessToken: signAccessToken(username),
      refreshToken: signRefreshToken(username),
    );
  }

  /// Exchanges a valid [refreshToken] for a fresh access token.
  ///
  /// Returns the new access token string, or `null` if the refresh token is
  /// invalid or expired (the client must ask the user to log in again).
  Future<String?> refresh(Session session, String refreshToken) async {
    final username = verifyRefreshToken(refreshToken);
    if (username == null) {
      session.log('Failed token refresh attempt', level: LogLevel.info);
      return null;
    }
    return signAccessToken(username);
  }
}
