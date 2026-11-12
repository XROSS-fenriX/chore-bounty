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
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.auth,
    this.bounties,
    this.households,
  });

  final AuthService? auth;
  final BountyService? bounties;
  final HouseholdService? households;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();

  late final TokenStorage _storage = TokenStorage();
  late final ApiClient _api = ApiClient(_storage);
  late final AuthService auth = widget.auth ?? AuthService(_api, _storage);
  late final BountyService bounties = widget.bounties ?? BountyService(_api);
  late final HouseholdService households =
      widget.households ?? HouseholdService(_api);

  bool busy = false;
  bool hidePassword = true;
  String? error;

  static const Color primaryGreen = Color(0xFF289851);
  static const Color darkTextColor = Color(0xFF6B452D);
  static const Color fieldFillColor = Color(0xFFF7F8F6);

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;

    setState(() {
      busy = true;
      error = null;
    });

    try {
      final AppUser user = await auth.login(
        email.text.trim(),
        password.text,
      );

      if (!mounted) return;

      if (!user.hasHouseholds) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HouseholdPromptScreen(
              auth: auth,
              bounties: bounties,
              households: households,
              user: user,
            ),
          ),
        );
      } else {
        await auth.storage.saveHouseholdId(
          user.households.first.id.toString(),
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeShell(
              auth: auth,
              bounties: bounties,
              households: households,
              user: user,
            ),
          ),
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

  void openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterScreen(
          auth: auth,
          bounties: bounties,
          households: households,
        ),
      ),
    );
  }

  InputDecoration inputStyle({
    required String hintText,
    required Widget prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.nunito(
        color: Colors.grey.shade400,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: fieldFillColor,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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

          // 2. Optional Back Button
          Positioned(
            top: 24,
            left: 8,
            child: SafeArea(
              child: Navigator.canPop(context)
                  ? CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.85),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: darkTextColor,
                          size: 18,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // 3. Floating Mascot / Logo
          Positioned(
            top: screenHeight * 0.08,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/welcome_hero_logo.png',
                width: 170,
                height: 170,
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
                height: screenHeight * 0.70,
                color: Colors.white,
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 48, 28, 16),
                    child: Form(
                      key: form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Sign In',
                            style: GoogleFonts.nunito(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: darkTextColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Welcome back, roommate! Ready for quests?',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8C7362),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Email field
                          TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: inputStyle(
                              hintText: 'Enter your email',
                              prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                                color: primaryGreen,
                              ),
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
                            controller: password,
                            obscureText: hidePassword,
                            decoration: inputStyle(
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: primaryGreen,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  hidePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade500,
                                ),
                                onPressed: () {
                                  setState(() {
                                    hidePassword = !hidePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

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
                            const SizedBox(height: 14),
                          ],

                          // Sign In Button
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
                                      'Sign In',
                                      style: GoogleFonts.nunito(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Switch to Register
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: GoogleFonts.nunito(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextButton(
                                onPressed: busy ? null : openRegister,
                                child: Text(
                                  'Get Started',
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
