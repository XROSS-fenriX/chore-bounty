import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/bounty_service.dart';
import '../widgets/ui.dart';
import 'home_shell.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.auth, required this.bounties});

  final AuthService auth;
  final BountyService bounties;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final form = GlobalKey<FormState>();

  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final confirm = TextEditingController();

  bool busy = false;
  bool hidePass = true;
  bool hideConfirm = true;
  String? error;

  static const Color primaryGreen = Color(0xFF289851);
  static const Color darkTextColor = Color(0xFF6B452D);
  static const Color fieldFillColor = Color(0xFFF7F8F6);

  @override
  void dispose() {
    name.dispose();
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
      final user = await widget.auth.register(
        name.text.trim(),
        email.text.trim(),
        pass.text,
        confirm.text,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomeShell(
            auth: widget.auth,
            bounties: widget.bounties,
            user: user,
          ),
        ),
        (_) => false,
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.35,
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
            top: screenHeight * 0.16,
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
                          Text(
                            'Join the Household',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: darkTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create your account and start earning rewards!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Name
                          TextFormField(
                            controller: name,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: _inputDecoration(
                              labelText: 'Full name',
                              prefixIcon: Icons.person_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

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
                                return 'Email is required.';
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
                            controller: pass,
                            obscureText: hidePass,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: _inputDecoration(
                              labelText: 'Password',
                              helperText: 'Use at least 8 characters.',
                              prefixIcon: Icons.lock_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  hidePass
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: Colors.grey,
                                ),
                                onPressed: () =>
                                    setState(() => hidePass = !hidePass),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 8) {
                                return 'Use at least 8 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Confirm Password
                          TextFormField(
                            controller: confirm,
                            obscureText: hideConfirm,
                            textInputAction: TextInputAction.done,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                            ),
                            onFieldSubmitted: (_) {
                              if (!busy) submit();
                            },
                            decoration: _inputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon: Icons.lock_reset_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  hideConfirm
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: Colors.grey,
                                ),
                                onPressed: () =>
                                    setState(() => hideConfirm = !hideConfirm),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password.';
                              }
                              if (value != pass.text) {
                                return 'Passwords do not match.';
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

                          // Submit Button
                          SizedBox(
                            height: 54,
                            child: GreenButton(
                              'Create Account',
                              loading: busy,
                              onPressed: busy ? null : submit,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Sign In Link
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
                                            builder: (_) => LoginScreen(
                                              auth: widget.auth,
                                              bounties: widget.bounties,
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
