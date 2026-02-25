import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:serverpod/serverpod.dart';

import 'jwt_auth.dart';

/// Exposes authentication operations.
///
/// Accessible from the client as `client.auth`.
class AuthEndpoint extends Endpoint {
  /// Validates [username]/[password] and returns a signed JWT on success,
  /// or `null` if the credentials are invalid.
  ///
  /// Returning null instead of throwing keeps invalid-credential events out of
  /// the server ERROR log — they are an expected client condition, not a fault.
  Future<String?> login(
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

    final jwt = JWT({
      'sub': username,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });

    return jwt.sign(
      SecretKey(jwtSecret),
      expiresIn: const Duration(hours: 1),
    );
  }
}
