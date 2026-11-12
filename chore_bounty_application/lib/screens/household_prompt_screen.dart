import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/app_user.dart';
import '../models/household.dart';
import '../services/auth_service.dart';
import '../services/bounty_service.dart';
import '../services/household_service.dart';
import 'home_shell.dart';
import 'login_screen.dart';

class HouseholdPromptScreen extends StatefulWidget {
  const HouseholdPromptScreen({
    super.key,
    required this.user,
    this.auth,
    this.bounties,
    this.households,
    this.isOptional = false,
  });

  final AppUser user;
  final AuthService? auth;
  final BountyService? bounties;
  final HouseholdService? households;
  final bool isOptional;

  @override
  State<HouseholdPromptScreen> createState() => _HouseholdPromptScreenState();
}

class _HouseholdPromptScreenState extends State<HouseholdPromptScreen> {
  int _activeTabIndex = 0; // 0: Create New, 1: Join by Code
  final createNameController = TextEditingController();
  final joinCodeController = TextEditingController();

  late final TokenStorage _storage = TokenStorage();
  late final ApiClient _api = ApiClient(_storage);
  late final AuthService auth = widget.auth ?? AuthService(_api, _storage);
  late final BountyService bounties = widget.bounties ?? BountyService(_api);
  late final HouseholdService households =
      widget.households ?? HouseholdService(_api);

  bool isBusy = false;
  String? errorMessage;

  @override
  void dispose() {
    createNameController.dispose();
    joinCodeController.dispose();
    super.dispose();
  }

  Future<void> handleCreate() async {
    final name = createNameController.text.trim();
    if (name.isEmpty) {
      setState(() => errorMessage = 'Please enter a household name.');
      return;
    }

    setState(() {
      isBusy = true;
      errorMessage = null;
    });

    try {
      final household = await households.create(name);
      await auth.storage.saveHouseholdId(household.id.toString());

      if (!mounted) return;

      if (widget.isOptional) {
        Navigator.pop(context, household);
      } else {
        _proceedToHome(household);
      }
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = households.error(e));
      }
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  Future<void> handleJoin() async {
    final code = joinCodeController.text.trim();
    if (code.isEmpty) {
      setState(() => errorMessage = 'Please enter an invite code.');
      return;
    }

    setState(() {
      isBusy = true;
      errorMessage = null;
    });

    try {
      final household = await households.join(code);
      await auth.storage.saveHouseholdId(household.id.toString());

      if (!mounted) return;

      if (widget.isOptional) {
        Navigator.pop(context, household);
      } else {
        _proceedToHome(household);
      }
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = households.error(e));
      }
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  void _proceedToHome(Household household) {
    final updatedUser = widget.user.copyWith(
      households: [...widget.user.households, household],
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeShell(
          auth: auth,
          bounties: bounties,
          households: households,
          user: updatedUser,
        ),
      ),
    );
  }

  Future<void> _handleBack() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    try {
      await auth.logout();
    } catch (_) {
      // Proceed back to login screen even if server logout fails.
    }
    if (!mounted) return;
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
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFAF8F5);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Full-width Hero Header (Occupies whole screen width; contains Top Bar)
              _buildFullWidthHeader(context),

              // 2. Main content area with standard comfortable padding
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Subtitle description
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Create bounties for shared chores among roommates. Choose whether to create a new household or join an existing one with an invite code.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Segmented Mode Toggle (Pills)
                    _buildModeToggle(),
                    const SizedBox(height: 20),

                    // Error message banner if any
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Form Card (Create New or Join by Code)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _activeTabIndex == 0
                          ? _buildCreateCard()
                          : _buildJoinCard(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullWidthHeader(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // Background illustration spanning the entire screen width
          Positioned.fill(
            child: Image.asset(
              'assets/images/household_header.jpg',
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.08),
            ),
          ),

          // Bottom white/cream blend gradient to transition cleanly into the page body
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 105,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.32, 0.68, 1.0],
                  colors: [
                    const Color(0xFFFAF8F5).withAlpha(0),
                    const Color(0xFFFAF8F5).withAlpha(170),
                    const Color(0xFFFAF8F5).withAlpha(245),
                    const Color(0xFFFAF8F5),
                  ],
                ),
              ),
            ),
          ),

          // Header content overlaid inside the full-width illustration
          Padding(
            padding: EdgeInsets.only(
              top: topPadding > 0 ? topPadding + 6 : 16,
              bottom: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Bar: Back button + Centered "Household Setup" Title
                SizedBox(
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: IconButton(
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              color: Color(0xFF1E293B),
                              size: 32,
                            ),
                            tooltip: 'Back',
                            onPressed: _handleBack,
                          ),
                        ),
                      ),
                      const Text(
                        'Household Setup',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Spacer allowing the cozy house illustration to remain visible
                const SizedBox(height: 132),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Create New Pill
          Expanded(
            child: _buildTogglePill(
              title: 'Create New',
              icon: Icons.add_home_rounded,
              isSelected: _activeTabIndex == 0,
              onTap: () {
                if (_activeTabIndex != 0) {
                  setState(() {
                    _activeTabIndex = 0;
                    errorMessage = null;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 4),

          // Join by Code Pill
          Expanded(
            child: _buildTogglePill(
              title: 'Join by Code',
              icon: Icons.vpn_key_rounded,
              isSelected: _activeTabIndex == 1,
              onTap: () {
                if (_activeTabIndex != 1) {
                  setState(() {
                    _activeTabIndex = 1;
                    errorMessage = null;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTogglePill({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const primaryGreen = Color(0xFF1B8354);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF22C55E) : Colors.transparent,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? primaryGreen : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? primaryGreen : const Color(0xFF64748B),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateCard() {
    return Container(
      key: const ValueKey('create_tab'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Household Name',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Give your household a unique and recognizable name.',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Input field
          TextFormField(
            controller: createNameController,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
            cursorColor: const Color(0xFF1B8354),
            decoration: InputDecoration(
              hintText: 'e.g. Apt 4B, Maple Street House',
              hintStyle: const TextStyle(
                fontSize: 14.5,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: const Icon(
                Icons.home_outlined,
                color: Color(0xFF64748B),
                size: 22,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.4),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF1B8354), width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Submit Action Button
          _buildSubmitButton(
            label: 'Create Guild',
            icon: Icons.add_circle_outline_rounded,
            onPressed: isBusy ? null : handleCreate,
          ),
        ],
      ),
    );
  }

  Widget _buildJoinCard() {
    return Container(
      key: const ValueKey('join_tab'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Apartment Invite Code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter the 6-character code shared by your roommate.',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Input field
          TextFormField(
            controller: joinCodeController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: 1.0,
            ),
            cursorColor: const Color(0xFF1B8354),
            decoration: InputDecoration(
              hintText: 'e.g. GUILD4B or APT4B123',
              hintStyle: const TextStyle(
                fontSize: 14.5,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.normal,
                letterSpacing: 0,
              ),
              prefixIcon: const Icon(
                Icons.key_rounded,
                color: Color(0xFF64748B),
                size: 22,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.4),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF1B8354), width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Submit Action Button
          _buildSubmitButton(
            label: 'Join Household',
            icon: Icons.login_rounded,
            onPressed: isBusy ? null : handleJoin,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null && !isBusy;
    const primaryGreen = Color(0xFF1B8354);

    return SizedBox(
      height: 54,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isEnabled ? primaryGreen : const Color(0xFFA7F3D0),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            if (isEnabled)
              BoxShadow(
                color: primaryGreen.withAlpha(50),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          icon: isBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, color: Colors.white, size: 20),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}
