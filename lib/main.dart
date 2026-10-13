import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/scheduler_provider.dart';
import 'screens/admin_gate.dart';
import 'screens/auth_gate.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/session_store.dart';
import 'theme/app_theme.dart';

void main() {
  usePathUrlStrategy(); // clean URLs: /admin instead of /#/admin
  WidgetsFlutterBinding.ensureInitialized();
  final AuthService auth;
  final ApiService api;
  if (AppConfig.useMock) {
    auth = MockAuthService();
    api = MockApiService();
  } else {
    final httpAuth = HttpAuthService(baseUrl: AppConfig.baseUrl);
    auth = httpAuth;
    api = HttpApiService(
        baseUrl: AppConfig.baseUrl, tokenProvider: () => httpAuth.token);
  }
  runApp(SchedulerApp(api: api, auth: auth, store: PrefsSessionStore()));
}

/// '/admin' -> admin-only page, anything else -> the student app.
Route<dynamic> _route(RouteSettings settings) {
  final path = Uri.tryParse(settings.name ?? '/')?.path ?? '/';
  final admin = path == '/admin' || path.startsWith('/admin/');
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => admin ? const AdminGate() : const AuthGate(),
  );
}

class SchedulerApp extends StatelessWidget {
  const SchedulerApp({super.key, this.api, this.auth, this.store});

  /// Injectable for tests.
  final ApiService? api;
  final AuthService? auth;
  final SessionStore? store;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AuthProvider(auth ?? MockAuthService(), store: store)
              ..restore()),
        // Data is loaded after sign-in (see AppShell).
        ChangeNotifierProvider(
            create: (_) => SchedulerProvider(api ?? MockApiService())),
      ],
      child: MaterialApp(
        title: 'Smart Sports Scheduler',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        onGenerateRoute: _route,
        // Open only the requested page (not '/' underneath it).
        onGenerateInitialRoutes: (name) => [_route(RouteSettings(name: name))],
      ),
    );
  }
}
