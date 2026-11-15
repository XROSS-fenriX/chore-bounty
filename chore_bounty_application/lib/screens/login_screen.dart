import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../services/auth_service.dart';
import '../services/bounty_service.dart';
import '../services/household_service.dart';
import '../widgets/auth/auth_form_components.dart';
import 'home_shell.dart';
import 'household_prompt_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService? auth;
  final BountyService? bounties;
  final HouseholdService? households;

  const LoginScreen({super.key, this.auth, this.bounties, this.households});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  AuthService get _effectiveAuth {
    if (widget.auth != null) return widget.auth!;
    final storage = TokenStorage();
    return AuthService(ApiClient(storage), storage);
  }

  BountyService get _effectiveBounties {
    if (widget.bounties != null) return widget.bounties!;
    return BountyService(ApiClient(TokenStorage()));
  }

  HouseholdService get _effectiveHouseholds {
    if (widget.households != null) return widget.households!;
    return HouseholdService(ApiClient(TokenStorage()));
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    final email = _email.text.trim();
    final pass = _password.text;

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (pass.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }

    setState(() => _loading = true);
    try {
      final auth = _effectiveAuth;
      final bounties = _effectiveBounties;
      final households = _effectiveHouseholds;

      final user = await auth.login(email, pass);
      if (!mounted) return;

      if (!user.hasHouseholds) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HouseholdPromptScreen(
              auth: auth,
              bounties: bounties,
              households: households,
              user: user,
            ),
          ),
        );
      } else {
        await auth.storage.saveHouseholdId(user.households.first.id.toString());
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomeShell(
              auth: auth,
              bounties: bounties,
              households: households,
              user: user,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = formatAuthError(
            e,
            fallbackMessage: 'Sign in failed. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(
          auth: _effectiveAuth,
          bounties: _effectiveBounties,
          households: _effectiveHouseholds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      centerVertically: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AuthTheme.ink,
                letterSpacing: -0.6,
                height: 1.15,
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Welcome back. Sign in to check household chores and bounties.',
            style: TextStyle(
              fontSize: 15,
              color: AuthTheme.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          if (_errorMessage != null) ...[
            AuthErrorBanner(message: _errorMessage!),
            const SizedBox(height: 20),
          ],
          AuthFieldGroup(
            label: 'Email Address',
            child: TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              style: AuthTheme.inputTextStyle,
              decoration: authInputDecoration(
                hintText: 'you@example.com',
                prefixIcon: Icons.mail_outline_rounded,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AuthFieldGroup(
            label: 'Password',
            child: TextField(
              controller: _password,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _login(),
              style: AuthTheme.inputTextStyle,
              decoration: authInputDecoration(
                hintText: 'Enter your password',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AuthTheme.muted,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: 'Sign In',
            isLoading: _loading,
            onPressed: _login,
          ),
          const SizedBox(height: 20),
            AuthFooterPrompt(
              prompt: "Don't have an account?",
              actionLabel: 'Get Started',
              onTap: _openRegister,
            ),
          ],
        ),
      ),
    );
  }
}
