import 'package:serverpod/serverpod.dart';

/// Protected "Hello World" endpoint.
///
/// Accessible from the client as `client.greeting`.
class GreetingEndpoint extends Endpoint {
  /// Only authenticated callers may invoke this method.
  @override
  bool get requireLogin => true;

  /// Returns a greeting for the authenticated user.
  Future<String> hello(Session session) async {
    final username = session.authenticated!.userIdentifier;
    return 'Hello, $username!';
  }
}
