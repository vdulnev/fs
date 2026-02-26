import 'package:jwt_app_client/jwt_app_client.dart';
import 'package:flutter/material.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

late final Client client;

/// Stores the access token and provides it as a Bearer header.
///
/// Intentionally implements only [ClientAuthKeyProvider] — not
/// [RefresherClientAuthKeyProvider] — to avoid a deadlock: the Mutex wrapper
/// calls [authHeaderValue] (→ refreshAuthKey) before *every* request,
/// including the refresh call itself, which would block forever waiting for the
/// pending refresh future to resolve.  Token refresh is handled explicitly in
/// the UI layer instead.
class _JwtAuthKeyProvider implements ClientAuthKeyProvider {
  String? _accessToken;
  String? _refreshToken;

  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clear() {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<String?> get authHeaderValue async =>
      _accessToken == null ? null : wrapAsBearerAuthHeaderValue(_accessToken!);
}

final _authProvider = _JwtAuthKeyProvider();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final serverUrl = await getServerUrl();

  client = Client(serverUrl)
    ..connectivityMonitor = FlutterConnectivityMonitor()
    ..authKeyProvider = _authProvider;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JWT Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(title: 'JWT Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoggedIn = false;
  String? _resultMessage;
  String? _errorMessage;

  void _callLogin() async {
    try {
      final tokens = await client.auth
          .login(_usernameController.text, _passwordController.text);
      if (tokens == null) {
        setState(() => _errorMessage = 'Invalid username or password.');
        return;
      }
      _authProvider.setTokens(tokens.accessToken, tokens.refreshToken);
      setState(() {
        _isLoggedIn = true;
        _errorMessage = null;
        _resultMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = '$e');
    }
  }

  void _callHello() async {
    try {
      final result = await client.greeting.hello();
      setState(() {
        _errorMessage = null;
        _resultMessage = result;
      });
    } on ServerpodClientUnauthorized {
      // Access token expired — try a silent refresh then retry once.
      final refreshed = await _tryRefresh();
      if (!refreshed) {
        _authProvider.clear();
        setState(() {
          _isLoggedIn = false;
          _errorMessage = 'Session expired. Please log in again.';
        });
        return;
      }
      try {
        final result = await client.greeting.hello();
        setState(() {
          _errorMessage = null;
          _resultMessage = result;
        });
      } catch (e) {
        setState(() => _errorMessage = '$e');
      }
    } catch (e) {
      setState(() => _errorMessage = '$e');
    }
  }

  /// Exchanges the stored refresh token for a new access token.
  /// Returns true on success, false if the refresh token is missing/expired.
  Future<bool> _tryRefresh() async {
    final rt = _authProvider._refreshToken;
    if (rt == null) return false;
    try {
      // Clear the access token first so this call goes out without an
      // Authorization header (avoids sending an expired token).
      _authProvider._accessToken = null;
      final newAt = await client.auth.refresh(rt);
      if (newAt == null) return false;
      _authProvider._accessToken = newAt;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _logout() {
    _authProvider.clear();
    setState(() {
      _isLoggedIn = false;
      _resultMessage = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_isLoggedIn)
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isLoggedIn) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(hintText: 'Username'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(hintText: 'Password'),
                  obscureText: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ElevatedButton(
                  onPressed: _callLogin,
                  child: const Text('Login'),
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ElevatedButton(
                  onPressed: _callHello,
                  child: const Text('Say Hello'),
                ),
              ),
            ],
            ResultDisplay(
              resultMessage: _resultMessage,
              errorMessage: _errorMessage,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class ResultDisplay extends StatelessWidget {
  final String? resultMessage;
  final String? errorMessage;

  const ResultDisplay({super.key, this.resultMessage, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    String text;
    Color backgroundColor;
    if (errorMessage != null) {
      backgroundColor = Colors.red[300]!;
      text = errorMessage!;
    } else if (resultMessage != null) {
      backgroundColor = Colors.green[300]!;
      text = resultMessage!;
    } else {
      backgroundColor = Colors.grey[300]!;
      text = 'No server response yet.';
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: Container(
        color: backgroundColor,
        child: Center(child: Text(text)),
      ),
    );
  }
}
