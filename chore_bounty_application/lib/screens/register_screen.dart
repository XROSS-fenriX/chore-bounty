import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/bounty_service.dart';
import '../services/household_service.dart';
import '../widgets/ui.dart';
import 'home_shell.dart';
import 'household_prompt_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    this.auth,
    this.bounties,
    this.households,
  });

  final AuthService? auth;
  final BountyService? bounties;
  final HouseholdService? households;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final form = GlobalKey<FormState>();

  final firstName = TextEditingController();
  final middleName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final confirm = TextEditingController();
  String? selectedGender;

  late final TokenStorage _storage = TokenStorage();
  late final ApiClient _api = ApiClient(_storage);
  late final AuthService auth = widget.auth ?? AuthService(_api, _storage);
  late final BountyService bounties = widget.bounties ?? BountyService(_api);
  late final HouseholdService households =
      widget.households ?? HouseholdService(_api);

  bool busy = false;
  bool hidePass = true;
  bool hideConfirm = true;
  String? error;

  static const Color primaryGreen = Color(0xFF289851);
  static const Color darkTextColor = Color(0xFF6B452D);
  static const Color fieldFillColor = Color(0xFFF7F8F6);

  @override
  void dispose() {
    firstName.dispose();
    middleName.dispose();
    lastName.dispose();
    email.dispose();
    pass.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    if (busy || !form.currentState!.validate()) {
      return;
    }

    setState(() {
      busy = true;
      error = null;
    });

    try {
      final user = await auth.register(
        firstName: firstName.text.trim(),
        middleName: middleName.text.trim(),
        lastName: lastName.text.trim(),
        gender: selectedGender!,
        email: email.text.trim(),
        password: pass.text,
        confirmation: confirm.text,
      );

      if (!mounted) return;

      if (!user.hasHouseholds) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HouseholdPromptScreen(
              auth: auth,
              bounties: bounties,
              households: households,
              user: user,
            ),
          ),
          (route) => false,
        );
      } else {
        await auth.storage.saveHouseholdId(
          user.households.first.id.toString(),
        );

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeShell(
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
      if (!mounted) return;

      setState(() {
        error = auth.error(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? hintText,
    String? helperText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      labelStyle: GoogleFonts.nunito(
        color: Colors.black54,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(prefixIcon, color: primaryGreen),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fieldFillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFD3E7B2),
      body: Stack(
        children: [
          // 1. Full-bleed Background
          Positioned.fill(
            bottom: screenHeight * 0.40,
            child: Image.asset(
              'assets/images/welcome_hero_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Back Button
          Positioned(
            top: 24,
            left: 8,
            child: SafeArea(
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.85),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: darkTextColor,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // 3. Floating Mascot / Logo
          Positioned(
            top: screenHeight * 0.04,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/welcome_hero_logo.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 4. White curved form sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipPath(
              clipper: TopCurveClipper(),
              child: Container(
                width: double.infinity,
                height: screenHeight * 0.78,
                color: Colors.white,
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 48, 28, 20),
                    child: Form(
                      key: form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Create Account',
                            style: GoogleFonts.nunito(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: darkTextColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Join your roommates and start earning bounties.',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8C7362),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // First Name field
                          TextFormField(
                            controller: firstName,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration(
                              labelText: 'First Name',
                              prefixIcon: Icons.person_outline_rounded,
                              hintText: 'e.g. Alex',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'First name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Middle Name (optional)
                          TextFormField(
                            controller: middleName,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration(
                              labelText: 'Middle Name (Optional)',
                              prefixIcon: Icons.person_outline_rounded,
                              hintText: 'Optional',
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Last Name field
                          TextFormField(
                            controller: lastName,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration(
                              labelText: 'Last Name',
                              prefixIcon: Icons.badge_outlined,
                              hintText: 'e.g. Mercer',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Gender field
                          DropdownButtonFormField<String>(
                            initialValue: selectedGender,
                            decoration: _inputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icons.wc_rounded,
                              hintText: 'Select your gender',
                            ),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            items: AppUser.genderOptions
                                .map(
                                  (opt) => DropdownMenuItem<String>(
                                    value: opt.value,
                                    child: Text(opt.label),
                                  ),
                                )
                                .toList(),
                            onChanged: busy
                                ? null
                                : (value) {
                                    setState(() => selectedGender = value);
                                  },
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please select a gender';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email field
                          TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icons.mail_outline_rounded,
                              hintText: 'e.g. alex@example.com',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!v.contains('@') || !v.contains('.')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: pass,
                            obscureText: hidePass,
                            decoration: _inputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icons.lock_outline_rounded,
                              hintText: 'At least 8 characters',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  hidePass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade500,
                                ),
                                onPressed: () {
                                  setState(() {
                                    hidePass = !hidePass;
                                  });
                                },
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password field
                          TextFormField(
                            controller: confirm,
                            obscureText: hideConfirm,
                            decoration: _inputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icons.lock_reset_rounded,
                              hintText: 'Re-enter your password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  hideConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade500,
                                ),
                                onPressed: () {
                                  setState(() {
                                    hideConfirm = !hideConfirm;
                                  });
                                },
                              ),
                            ),
                            validator: (v) {
                              if (v != pass.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          if (error != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      error!,
                                      style: GoogleFonts.nunito(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Submit Button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: busy ? null : submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: busy
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Create Account',
                                      style: GoogleFonts.nunito(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Switch to Sign In
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account?',
                                style: GoogleFonts.nunito(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => LoginScreen(
                                              auth: auth,
                                              bounties: bounties,
                                              households: households,
                                            ),
                                          ),
                                        );
                                      },
                                child: Text(
                                  'Sign In',
                                  style: GoogleFonts.nunito(
                                    color: primaryGreen,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
