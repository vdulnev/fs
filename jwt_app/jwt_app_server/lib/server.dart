import 'package:serverpod/serverpod.dart';

import 'src/generated/protocol.dart';
import 'src/generated/endpoints.dart';
import 'src/jwt_auth.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  final pod = Serverpod(
    args,
    Protocol(),
    Endpoints(),
    // Validate incoming JWT tokens for every authenticated request.
    authenticationHandler: jwtAuthHandler,
  );

  await pod.start();
}
