import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/scheduler_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/sidebar_nav.dart';
import '../widgets/surface.dart';

/// Login + registration in one animated screen.
/// Desktop: navy brand panel + form. Mobile: logo above the form.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _login = true;
  bool _hidePw = true;
  bool _hidePw2 = true;

  final _loginKey = GlobalKey<FormState>();
  final _registerKey = GlobalKey<FormState>();
  final _loginEmail = TextEditingController();
  final _loginPw = TextEditingController();
  final _name = TextEditingController();
  final _studentId = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _loginEmail,
      _loginPw,
      _name,
      _studentId,
      _email,
      _pw,
      _pw2
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setMode(bool login) {
    if (_login == login) return;
    context.read<AuthProvider>().clearError();
    setState(() => _login = login);
  }

  Future<void> _submit() async {
    final key = _login ? _loginKey : _registerKey;
    if (!key.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final scheduler = context.read<SchedulerProvider>();
    final ok = _login
        ? await auth.login(email: _loginEmail.text, password: _loginPw.text)
        : await auth.register(
            name: _name.text,
            studentId: _studentId.text,
            email: _email.text,
            password: _pw.text);
    if (ok && auth.user != null) {
      scheduler.setProfile(auth.user!.name, auth.user!.studentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final form = SurfaceCard(
      padding: const EdgeInsets.all(28),
      child: _buildForm(auth),
    );

    return Scaffold(
      body: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth >= 900) {
          return Row(
            children: [
              const Expanded(flex: 5, child: _BrandPanel()),
              Expanded(
                flex: 4,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: form),
                  ),
                ),
              ),
            ],
          );
        }
        return SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [const AppLogo(), const SizedBox(height: 24), form],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildForm(AuthProvider auth) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModeToggle(login: _login, onChanged: _setMode),
        const SizedBox(height: 24),
        Text(_login ? 'Welcome back' : 'Create your account',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
            _login
                ? 'Log in to book and manage your sports facilities.'
                : 'Register with your user details to start booking.',
            style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 22),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _login
                ? KeyedSubtree(
                    key: const ValueKey('login'), child: _loginForm())
                : KeyedSubtree(
                    key: const ValueKey('register'), child: _registerForm()),
          ),
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
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: auth.busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
              : Text(_login ? 'Log in' : 'Create account'),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => _setMode(!_login),
            child: Text(_login
                ? "Don't have an account? Register"
                : 'Already registered? Log in'),
          ),
        ),
      ],
    );
  }

  Widget _loginForm() => Form(
        key: _loginKey,
        child: Column(
          children: [
            TextFormField(
              controller: _loginEmail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                  labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _loginPw,
              obscureText: _hidePw,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _hidePw = !_hidePw),
                  icon: Icon(_hidePw
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                ),
              ),
              validator: (v) =>
                  (v ?? '').isEmpty ? 'Password is required' : null,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
              decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 18, color: AppColors.blue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Demo: demo@user.edu · Demo@1234',
                        style:
                            TextStyle(fontSize: 12.5, color: AppColors.blue)),
                  ),
                  TextButton(
                    onPressed: () {
                      _loginEmail.text = 'demo@user.edu';
                      _loginPw.text = 'Demo@1234';
                    },
                    child: const Text('Use'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _registerForm() => Form(
        key: _registerKey,
        child: Column(
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline)),
              validator: Validators.name,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _studentId,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                  labelText: ' ID', prefixIcon: Icon(Icons.badge_outlined)),
              validator: Validators.studentId,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                  labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pw,
              obscureText: _hidePw,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: 'At least 8 characters, with a letter and a number',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _hidePw = !_hidePw),
                  icon: Icon(_hidePw
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                ),
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pw2,
              obscureText: _hidePw2,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _hidePw2 = !_hidePw2),
                  icon: Icon(_hidePw2
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                ),
              ),
              validator: (v) => Validators.confirmPassword(v, _pw.text),
            ),
          ],
        ),
      );
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.login, required this.onChanged});
  final bool login;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String text, bool selected, bool value) => Expanded(
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: selected ? AppShadows.soft : const [],
              ),
              child: Center(
                child: Text(text,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: selected ? AppColors.blue : AppColors.muted)),
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: AppColors.tint, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        seg('Log in', login, true),
        seg('Register', !login, false)
      ]),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    Widget point(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Text(text,
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
        );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.slateDeep, AppColors.slate, AppColors.blue],
        ),
      ),
      padding: const EdgeInsets.all(56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLogo(light: true),
          const Spacer(),
          Text('Book sports\nfacilities in seconds.'.toUpperCase(),
              style: AppText.display(34, color: Colors.white)),
          const SizedBox(height: 14),
          const Text(
              'One place to find courts, fields and halls, and track every request.',
              style:
                  TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
          const SizedBox(height: 32),
          point(Icons.event_available_outlined, 'Live slot availability'),
          point(Icons.auto_awesome, 'Smart recommendations and best times'),
          point(Icons.verified_outlined, 'Clear booking status updates'),
          const Spacer(),
          const Text('Smart Sports Scheduler · v1.0',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
