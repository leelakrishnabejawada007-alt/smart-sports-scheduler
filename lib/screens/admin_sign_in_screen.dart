import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/sidebar_nav.dart';
import '../widgets/surface.dart';

/// Sign-in used at /admin. Only accounts with the admin role get through.
class AdminSignInScreen extends StatefulWidget {
  const AdminSignInScreen({super.key});

  @override
  State<AdminSignInScreen> createState() => _AdminSignInScreenState();
}

class _AdminSignInScreenState extends State<AdminSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context
        .read<AuthProvider>()
        .adminLogin(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.slateDeep, AppColors.slate, AppColors.blue],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    const AppLogo(light: true),
                    const SizedBox(height: 28),
                    SurfaceCard(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ADMIN ONLY', style: AppText.eyebrow()),
                            const SizedBox(height: 8),
                            Text('ADMIN SIGN IN', style: AppText.display(26)),
                            const SizedBox(height: 6),
                            const Text('This area is restricted to administrators.',
                                style: TextStyle(color: AppColors.muted)),
                            const SizedBox(height: 22),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                  labelText: 'Admin email',
                                  prefixIcon: Icon(Icons.mail_outline)),
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: _hide,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() => _hide = !_hide),
                                  icon: Icon(_hide
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                ),
                              ),
                              validator: (v) =>
                                  (v ?? '').isEmpty ? 'Password is required' : null,
                            ),
                            if (auth.error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: AppColors.dangerBg,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 18, color: AppColors.danger),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(auth.error!,
                                          style: const TextStyle(
                                              color: AppColors.danger, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: auth.busy ? null : _submit,
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52)),
                              child: auth.busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5, color: Colors.white))
                                  : const Text('Sign in'),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pushReplacementNamed('/'),
                                child: const Text('Back to student app'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
