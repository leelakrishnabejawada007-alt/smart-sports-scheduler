import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/session.dart';
import '../widgets/sidebar_nav.dart';
import 'admin_screen.dart';
import 'admin_sign_in_screen.dart';

/// What you see at /admin:
///  - not signed in            -> admin sign-in
///  - signed in as a student   -> "Admin access only"
///  - signed in as an admin    -> the dashboard
class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final Widget child;
    if (auth.restoring) {
      child = const Scaffold(
        key: ValueKey('splash'),
        body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    } else if (!auth.isAuthenticated) {
      child = const AdminSignInScreen(key: ValueKey('signin'));
    } else if (!auth.isAdmin) {
      child = const _AccessDenied(key: ValueKey('denied'));
    } else {
      child = const _AdminShell(key: ValueKey('admin'));
    }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: child);
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                        color: AppColors.dangerBg, shape: BoxShape.circle),
                    child: const Icon(Icons.lock_outline,
                        size: 34, color: AppColors.danger),
                  ),
                  const SizedBox(height: 18),
                  Text('ADMIN ACCESS ONLY', style: AppText.display(22)),
                  const SizedBox(height: 8),
                  const Text(
                      'You are signed in with a student account, which cannot open this page.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/'),
                    child: const Text('Back to student app'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                    onPressed: () => logOut(context),
                    child: const Text('Log out and sign in as admin'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _AdminShell extends StatelessWidget {
  const _AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthProvider, String>((a) => a.user?.name ?? 'Admin');
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            const AppLogo(),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.slate, borderRadius: BorderRadius.circular(20)),
              child: Text('ADMIN',
                  style: AppText.label(10.5, color: Colors.white, spacing: 1.6)),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: const Text('Student app'),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: 'Signed in as $name · Log out',
            child: IconButton(
              onPressed: () => logOut(context),
              icon: const Icon(Icons.logout),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.9, -0.9),
            radius: 1.3,
            colors: [Color(0xFFDCEAF8), AppColors.background],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: const AdminScreen(standalone: true),
          ),
        ),
      ),
    );
  }
}
