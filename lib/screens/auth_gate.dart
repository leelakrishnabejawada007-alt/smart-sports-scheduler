import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/sidebar_nav.dart';
import 'app_shell.dart';
import 'auth_screen.dart';

/// Splash while a saved login is restored, then login/registration or the app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final restoring = context.select<AuthProvider, bool>((a) => a.restoring);
    final signedIn = context.select<AuthProvider, bool>((a) => a.isAuthenticated);

    final Widget child = restoring
        ? const Scaffold(
            key: ValueKey('splash'),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLogo(),
                  SizedBox(height: 24),
                  SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.blue)),
                ],
              ),
            ),
          )
        : signedIn
            ? const AppShell(key: ValueKey('app'))
            : const AuthScreen(key: ValueKey('auth'));

    return AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: child);
  }
}
