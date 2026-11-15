import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../services/auth_service.dart';
import '../services/bounty_service.dart';
import '../services/household_service.dart';
import '../widgets/auth/auth_form_components.dart';
import '../widgets/ui.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final AuthService? auth;
  final BountyService? bounties;
  final HouseholdService? households;

  const WelcomeScreen({super.key, this.auth, this.bounties, this.households});

  AuthService get _effectiveAuth {
    if (auth != null) return auth!;
    final storage = TokenStorage();
    return AuthService(ApiClient(storage), storage);
  }

  BountyService get _effectiveBounties {
    if (bounties != null) return bounties!;
    return BountyService(ApiClient(TokenStorage()));
  }

  HouseholdService get _effectiveHouseholds {
    if (households != null) return households!;
    return HouseholdService(ApiClient(TokenStorage()));
  }

  void _openRegister(BuildContext context) {
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

  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          auth: _effectiveAuth,
          bounties: _effectiveBounties,
          households: _effectiveHouseholds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isCompact = screenHeight < 680;

    return AuthPageScaffold(
      centerVertically: true,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isCompact ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: BrandMark(size: isCompact ? 112 : 132)),
            SizedBox(height: isCompact ? 24 : 32),
            const Text(
              'Turn Chores Into Bounties',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AuthTheme.ink,
                letterSpacing: -0.6,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Complete household tasks, earn rewards from your roommates, and climb the apartment leaderboard.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AuthTheme.muted,
                height: 1.5,
              ),
            ),
            SizedBox(height: isCompact ? 32 : 44),
            AuthPrimaryButton(
              label: 'Get Started',
              onPressed: () => _openRegister(context),
            ),
            const SizedBox(height: 12),
            AuthSecondaryButton(
              label: 'Sign In',
              onPressed: () => _openLogin(context),
            ),
          ],
        ),
      ),
    );
  }
}
