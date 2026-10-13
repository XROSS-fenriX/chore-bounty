import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/bounty_service.dart';
import '../widgets/ui.dart';
import 'home_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth, required this.bounties});

  final AuthService auth;
  final BountyService bounties;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();

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
    FocusScope.of(context).unfocus();

    if (busy || !form.currentState!.validate()) {
      return;
    }

    setState(() {
      busy = true;
      error = null;
    });

    try {
      final AppUser user = await widget.auth.login(
        email.text.trim(),
        password.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeShell(
            auth: widget.auth,
            bounties: widget.bounties,
            user: user,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = widget.auth.error(e);
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
        builder: (_) =>
            RegisterScreen(auth: widget.auth, bounties: widget.bounties),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.40,
            child: Image.asset(
              'assets/images/welcome_hero_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Top App Bar / Back Navigation
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Navigator.canPop(context)
                    ? CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.85),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: darkTextColor,
                            size: 18,
                          ),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),

          // 3. Full-width Curved Bottom Sheet containing the Form
          Positioned(
            top: screenHeight * 0.22,
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipPath(
              clipper: TopCurveClipper(),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(24, 38, 24, 16),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SafeArea(
                    top: false,
                    child: Form(
                      key: form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          // Brand Icon & Header
                          const Center(child: BrandMark(size: 64)),
                          const SizedBox(height: 12),
                          Text(
                            'Welcome Back!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: darkTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sign in to check your household quests.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Email
                          TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: _inputDecoration(
                              labelText: 'Email address',
                              hintText: 'you@example.com',
                              prefixIcon: Icons.email_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter your email address.';
                              }
                              if (!value.contains('@')) {
                                return 'Enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: password,
                            obscureText: hidePassword,
                            textInputAction: TextInputAction.done,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                            ),
                            onFieldSubmitted: (_) {
                              if (!busy) submit();
                            },
                            decoration: _inputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icons.lock_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  hidePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: Colors.grey,
                                ),
                                onPressed: () => setState(
                                  () => hidePassword = !hidePassword,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter your password.';
                              }
                              return null;
                            },
                          ),

                          // Error
                          if (error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.red.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      error!,
                                      style: GoogleFonts.nunito(
                                        color: Colors.red.shade800,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 22),

                          // Sign In Button
                          SizedBox(
                            height: 54,
                            child: GreenButton(
                              'Sign In',
                              loading: busy,
                              onPressed: busy ? null : submit,
                            ),
                          ),
                          const SizedBox(height: 16),

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

class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 32);
    path.quadraticBezierTo(size.width / 2, -12, size.width, 32);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
