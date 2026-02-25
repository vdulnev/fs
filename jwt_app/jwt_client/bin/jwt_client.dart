import 'dart:io';

import 'package:jwt_app_client/jwt_app_client.dart';

const _serverUrl = 'http://localhost:8080/';

void main(List<String> args) async {
  final username = args.isNotEmpty ? args[0] : 'alice';
  final password = args.length > 1 ? args[1] : 'password123';

  // --- Build the client ---------------------------------------------------
  final jwtProvider = _JwtKeyProvider();
  final client = Client(_serverUrl)..authKeyProvider = jwtProvider;

  print('=== JWT Serverpod Client ===');

  // --- Step 1: login → obtain JWT -----------------------------------------
  print('Logging in as "$username"...');
  try {
    final token = await client.auth.login(username, password);
    if (token == null) {
      stderr.writeln('Login failed: invalid credentials.');
      exit(1);
    }
    jwtProvider.setToken(token);
    print('Token received: ${_abbreviate(token)}\n');
  } on ServerpodClientException catch (e) {
    stderr.writeln('Login error: ${e.message}');
    exit(1);
  }

  // --- Step 2: call the protected hello endpoint --------------------------
  print('Calling greeting.hello()...');
  try {
    final message = await client.greeting.hello();
    print('Server says: $message');
  } on ServerpodClientException catch (e) {
    stderr.writeln('Call failed: ${e.message}');
    exit(1);
  }

  client.close();
}

// ---------------------------------------------------------------------------
// Auth key provider — stores the JWT and sends it as "Bearer <token>"
// ---------------------------------------------------------------------------

class _JwtKeyProvider implements ClientAuthKeyProvider {
  String? _token;

  void setToken(String token) => _token = token;

  @override
  Future<String?> get authHeaderValue async =>
      _token != null ? 'Bearer $_token' : null;
}

String _abbreviate(String s) =>
    s.length > 40 ? '${s.substring(0, 40)}…' : s;
