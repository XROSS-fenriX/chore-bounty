import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/app_user.dart';
import '../models/household.dart';
import '../services/auth_service.dart';
import '../services/bounty_service.dart';
import '../services/household_service.dart';
import '../widgets/auth/auth_form_components.dart';
import '../widgets/dashboard/dashboard_filter_pills.dart';
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
  static const List<String> _modes = ['Create New', 'Join by Code'];

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
    FocusScope.of(context).unfocus();
    final name = createNameController.text.trim();
    if (name.isEmpty) {
      setState(() => errorMessage = 'Please enter a household name.');
      return;
    }

    await _submitHouseholdAction(() => households.create(name));
  }

  Future<void> handleJoin() async {
    FocusScope.of(context).unfocus();
    final code = joinCodeController.text.trim();
    if (code.isEmpty) {
      setState(() => errorMessage = 'Please enter an invite code.');
      return;
    }

    await _submitHouseholdAction(() => households.join(code));
  }

  Future<void> _submitHouseholdAction(
    Future<Household> Function() request,
  ) async {
    setState(() {
      isBusy = true;
      errorMessage = null;
    });

    try {
      final household = await request();
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
    final isCreate = _activeTabIndex == 0;

    return AuthPageScaffold(
      showBackButton: true,
      onBack: isBusy ? null : _handleBack,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Household Setup',
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
              'Create a new household or join an existing one with an invite code.',
              style: TextStyle(
                fontSize: 15,
                color: AuthTheme.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            DashboardFilterPills(
              filters: _modes,
              selectedFilter: _modes[_activeTabIndex],
              onFilterChanged: (label) {
                final nextIndex = label == _modes[0] ? 0 : 1;
                if (_activeTabIndex == nextIndex) return;
                setState(() {
                  _activeTabIndex = nextIndex;
                  errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 24),
            if (errorMessage != null) ...[
              AuthErrorBanner(message: errorMessage!),
              const SizedBox(height: 20),
            ],
            if (isCreate)
              AuthFieldGroup(
                label: 'Household Name',
                child: TextField(
                  key: const ValueKey('create_household_name_field'),
                  controller: createNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!isBusy) handleCreate();
                  },
                  style: AuthTheme.inputTextStyle,
                  decoration: authInputDecoration(
                    hintText: 'e.g. Apt 4B, Maple Street House',
                    prefixIcon: Icons.home_outlined,
                  ),
                ),
              )
            else
              AuthFieldGroup(
                label: 'Invite Code',
                child: TextField(
                  key: const ValueKey('join_household_code_field'),
                  controller: joinCodeController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!isBusy) handleJoin();
                  },
                  style: AuthTheme.inputTextStyle,
                  decoration: authInputDecoration(
                    hintText: 'e.g. APT4B123',
                    prefixIcon: Icons.vpn_key_outlined,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: isCreate ? 'Create Household' : 'Join Household',
              isLoading: isBusy,
              onPressed: isCreate ? handleCreate : handleJoin,
            ),
          ],
        ),
      ),
    );
  }
}
