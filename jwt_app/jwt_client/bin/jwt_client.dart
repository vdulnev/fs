import 'dart:io';

import 'package:jwt_app_client/jwt_app_client.dart';

const _serverUrl = 'http://localhost:8080/';

void main(List<String> args) async {
  final username = args.isNotEmpty ? args[0] : 'alice';
  final password = args.length > 1 ? args[1] : 'password123';

  final jwtProvider = _JwtKeyProvider();
  final client = Client(_serverUrl)..authKeyProvider = jwtProvider;

  print('=== JWT Serverpod Client ===\n');

  // ── 1. Login ──────────────────────────────────────────────────────────────
  print('Step 1: login as "$username"...');
  final tokens = await _login(client, username, password);
  if (tokens == null) {
    stderr.writeln('Login failed: invalid credentials.');
    exit(1);
  }
  jwtProvider.setToken(tokens.accessToken);
  print('  access token : ${_abbreviate(tokens.accessToken)}');
  print('  refresh token: ${_abbreviate(tokens.refreshToken)}\n');

  // ── 2. Normal call — access token is still valid, no refresh needed ───────
  print('Step 2: greeting.hello() — token is valid...');
  await _helloWithAutoRefresh(client, jwtProvider, tokens.refreshToken);

  // ── 3. Simulate an expired access token ───────────────────────────────────
  print('\nStep 3: simulating an expired access token...');
  jwtProvider.setToken('this.is.expired');

  // ── 4. hello() now gets a 401 → auto-refresh → retry ─────────────────────
  print('Step 4: greeting.hello() — token expired, auto-refresh triggers...');
  await _helloWithAutoRefresh(client, jwtProvider, tokens.refreshToken);

  client.close();
}

// ── Core helper: only refreshes on 401 ───────────────────────────────────────

/// Calls [greeting.hello].
/// If the server responds with 401 (access token expired), refreshes the
/// access token once and retries.  Does NOT refresh on success.
Future<void> _helloWithAutoRefresh(
  Client client,
  _JwtKeyProvider provider,
  String refreshToken,
) async {
  try {
    print('  Server says: ${await client.greeting.hello()}');
    return; // ← success: no refresh needed
  } on ServerpodClientException catch (e) {
    if (e.statusCode != 401) {
      stderr.writeln('  Unexpected error (${e.statusCode}): ${e.message}');
      return;
    }
  }

  // Access token was rejected — try to get a new one.
  print('  Got 401. Refreshing access token...');
  final newToken = await _refresh(client, refreshToken);
  if (newToken == null) {
    stderr.writeln('  Refresh token invalid or expired. Please log in again.');
    return;
  }
  provider.setToken(newToken);
  print('  New access token: ${_abbreviate(newToken)}');

  // One retry with the fresh token.
  try {
    print('  Retrying... Server says: ${await client.greeting.hello()}');
  } on ServerpodClientException catch (e) {
    stderr.writeln('  Retry failed (${e.statusCode}): ${e.message}');
  }
}

// ── Low-level API helpers ─────────────────────────────────────────────────────

Future<AuthTokens?> _login(
  Client client,
  String username,
  String password,
) async {
  try {
    return await client.auth.login(username, password);
  } on ServerpodClientException catch (e) {
    stderr.writeln('Login error: ${e.message}');
    return null;
  }
}

Future<String?> _refresh(Client client, String refreshToken) async {
  try {
    return await client.auth.refresh(refreshToken);
  } on ServerpodClientException catch (e) {
    stderr.writeln('Refresh error: ${e.message}');
    return null;
  }
}

// ── Auth key provider ─────────────────────────────────────────────────────────

class _JwtKeyProvider implements ClientAuthKeyProvider {
  String? _token;

  void setToken(String token) => _token = token;

  @override
  Future<String?> get authHeaderValue async =>
      _token != null ? 'Bearer $_token' : null;
}

String _abbreviate(String s) =>
    s.length > 40 ? '${s.substring(0, 40)}…' : s;
