import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _baseUrl = 'http://localhost:8080';

void main(List<String> args) async {
  // Allow overriding credentials via command-line args:
  //   dart run bin/jwt_client.dart alice password123
  final username = args.isNotEmpty ? args[0] : 'alice';
  final password = args.length > 1 ? args[1] : 'password123';

  print('=== JWT Client ===');
  print('Logging in as "$username"...');

  // 1. Login → obtain JWT
  final token = await _login(username, password);
  if (token == null) {
    stderr.writeln('Login failed. Exiting.');
    exit(1);
  }
  print('Token received: ${_abbreviate(token)}\n');

  // 2. Call the protected /hello endpoint
  print('Calling GET /hello...');
  await _hello(token);
}

// ---------------------------------------------------------------------------
// API calls
// ---------------------------------------------------------------------------

Future<String?> _login(String username, String password) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/login'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({'username': username, 'password': password}),
  );

  final body = _decodeBody(response);

  if (response.statusCode == 200) {
    return body['token'] as String?;
  }

  stderr.writeln('Login error ${response.statusCode}: ${body['error']}');
  return null;
}

Future<void> _hello(String token) async {
  final response = await http.get(
    Uri.parse('$_baseUrl/hello'),
    headers: {'authorization': 'Bearer $token'},
  );

  final body = _decodeBody(response);

  if (response.statusCode == 200) {
    print('Server says: ${body['message']}');
  } else {
    stderr.writeln('Error ${response.statusCode}: ${body['error']}');
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _decodeBody(http.Response response) {
  try {
    return jsonDecode(response.body) as Map<String, dynamic>;
  } catch (_) {
    return {'raw': response.body};
  }
}

/// Show only first 40 chars of a JWT so it doesn't clutter the terminal.
String _abbreviate(String token) =>
    token.length > 40 ? '${token.substring(0, 40)}…' : token;
