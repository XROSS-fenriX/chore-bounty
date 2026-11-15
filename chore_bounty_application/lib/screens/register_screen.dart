import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/bounty_service.dart';
import '../services/household_service.dart';
import '../widgets/auth/auth_form_components.dart';
import 'home_shell.dart';
import 'household_prompt_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService? auth;
  final BountyService? bounties;
  final HouseholdService? households;

  const RegisterScreen({super.key, this.auth, this.bounties, this.households});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  String? _selectedGender;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
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
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    final firstName = _firstName.text.trim();
    final middleName = _middleName.text.trim();
    final lastName = _lastName.text.trim();
    final email = _email.text.trim();
    final pass = _pass.text;
    final confirm = _confirm.text;

    if (firstName.isEmpty) {
      setState(() => _errorMessage = 'Please enter your first name.');
      return;
    }
    if (lastName.isEmpty) {
      setState(() => _errorMessage = 'Please enter your last name.');
      return;
    }
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      setState(() => _errorMessage = 'Please select your gender.');
      return;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (pass.length < 8) {
      setState(
        () => _errorMessage = 'Password must be at least 8 characters.',
      );
      return;
    }
    if (pass != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() => _loading = true);
    try {
      final auth = _effectiveAuth;
      final bounties = _effectiveBounties;
      final households = _effectiveHouseholds;

      final user = await auth.register(
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        gender: _selectedGender!,
        email: email,
        password: pass,
        confirmation: confirm,
      );
      if (!mounted) return;

      if (!user.hasHouseholds) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => HouseholdPromptScreen(
              auth: auth,
              bounties: bounties,
              households: households,
              user: user,
            ),
          ),
          (route) => false,
        );
      } else {
        await auth.storage.saveHouseholdId(user.households.first.id.toString());
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => HomeShell(
              auth: auth,
              bounties: bounties,
              households: households,
              user: user,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = formatAuthError(
            e,
            fallbackMessage: 'Registration failed. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          auth: _effectiveAuth,
          bounties: _effectiveBounties,
          households: _effectiveHouseholds,
        ),
      ),
    );
  }

  Widget _buildFirstNameField() {
    return AuthFieldGroup(
      label: 'First Name',
      child: TextField(
        controller: _firstName,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.givenName],
        style: AuthTheme.inputTextStyle,
        decoration: authInputDecoration(
          hintText: 'Leonard',
          prefixIcon: Icons.person_outline_rounded,
        ),
      ),
    );
  }

  Widget _buildLastNameField() {
    return AuthFieldGroup(
      label: 'Last Name',
      child: TextField(
        controller: _lastName,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.familyName],
        style: AuthTheme.inputTextStyle,
        decoration: authInputDecoration(
          hintText: 'Hofstadter',
          prefixIcon: Icons.badge_outlined,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      centerVertically: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create Account',
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
            'Join your roommates and start claiming household bounties.',
            style: TextStyle(
              fontSize: 15,
              color: AuthTheme.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null) ...[
            AuthErrorBanner(message: _errorMessage!),
            const SizedBox(height: 20),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 340) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildFirstNameField()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildLastNameField()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildFirstNameField(),
                  const SizedBox(height: 16),
                  _buildLastNameField(),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          AuthFieldGroup(
            label: 'Middle Name',
            isOptional: true,
            child: TextField(
              controller: _middleName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.middleName],
              style: AuthTheme.inputTextStyle,
              decoration: authInputDecoration(
                hintText: 'Leakey',
                prefixIcon: Icons.person_outline_rounded,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AuthFieldGroup(
            label: 'Gender',
            child: DropdownButtonFormField<String>(
              initialValue: _selectedGender,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AuthTheme.muted,
              ),
              style: AuthTheme.inputTextStyle,
              dropdownColor: AuthTheme.surface,
              decoration: authInputDecoration(
                hintText: 'Select your gender',
                prefixIcon: Icons.wc_rounded,
              ),
              items: AppUser.genderOptions
                  .map(
                    (opt) => DropdownMenuItem<String>(
                      value: opt.value,
                      child: Text(opt.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedGender = value);
              },
            ),
          ),
          const SizedBox(height: 16),
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
              controller: _pass,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              style: AuthTheme.inputTextStyle,
              decoration: authInputDecoration(
                hintText: 'At least 8 characters',
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
          const SizedBox(height: 16),
          AuthFieldGroup(
            label: 'Confirm Password',
            child: TextField(
              controller: _confirm,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _register(),
              style: AuthTheme.inputTextStyle,
              decoration: authInputDecoration(
                hintText: 'Re-enter your password',
                prefixIcon: Icons.lock_reset_rounded,
                suffixIcon: IconButton(
                  tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AuthTheme.muted,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: 'Create Account',
            isLoading: _loading,
            onPressed: _register,
          ),
          const SizedBox(height: 20),
            AuthFooterPrompt(
              prompt: 'Already have an account?',
              actionLabel: 'Sign In',
              onTap: _openLogin,
            ),
          ],
        ),
      ),
    );
  }
}
