import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

// Change this to a strong secret in production (e.g. load from env).
const _jwtSecret = 'super-secret-key-change-me';

// Demo credentials store.
const _users = {'alice': 'password123', 'bob': 'qwerty'};

void main() async {
  final router = Router();

  // POST /login  →  returns JWT
  router.post('/login', _loginHandler);

  // GET /hello  →  protected, requires Bearer JWT
  router.get('/hello', _helloHandler);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server listening on http://localhost:${server.port}');
}

// ---------------------------------------------------------------------------
// Handlers
// ---------------------------------------------------------------------------

Future<Response> _loginHandler(Request request) async {
  final body = await request.readAsString();
  Map<String, dynamic> data;
  try {
    data = jsonDecode(body) as Map<String, dynamic>;
  } catch (_) {
    return _json({'error': 'Invalid JSON'}, statusCode: 400);
  }

  final username = data['username'] as String?;
  final password = data['password'] as String?;

  if (username == null || password == null) {
    return _json({'error': 'username and password required'}, statusCode: 400);
  }

  if (_users[username] != password) {
    return _json({'error': 'Invalid credentials'}, statusCode: 401);
  }

  final jwt = JWT({'sub': username, 'iat': _nowEpoch()});
  final token = jwt.sign(
    SecretKey(_jwtSecret),
    expiresIn: const Duration(hours: 1),
  );

  return _json({'token': token});
}

Future<Response> _helloHandler(Request request) async {
  final authHeader = request.headers['authorization'] ?? '';
  if (!authHeader.startsWith('Bearer ')) {
    return _json({'error': 'Missing or malformed Authorization header'},
        statusCode: 401);
  }

  final token = authHeader.substring(7);
  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    final subject = (jwt.payload as Map<String, dynamic>)['sub'] as String?;
    return _json({'message': 'Hello, $subject!'});
  } on JWTExpiredException {
    return _json({'error': 'Token expired'}, statusCode: 401);
  } on JWTException catch (e) {
    return _json({'error': 'Invalid token: ${e.message}'}, statusCode: 401);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Response _json(Map<String, dynamic> body, {int statusCode = 200}) => Response(
      statusCode,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );

int _nowEpoch() =>
    DateTime.now().millisecondsSinceEpoch ~/ 1000;
