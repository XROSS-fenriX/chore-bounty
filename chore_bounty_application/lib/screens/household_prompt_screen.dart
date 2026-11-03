import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/constants/rpg_theme.dart';
import '../core/token_storage.dart';
import '../models/app_user.dart';
import '../models/household.dart';
import '../services/auth_service.dart';
import '../services/bounty_service.dart';
import '../services/household_service.dart';
import 'home_shell.dart';

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

class _HouseholdPromptScreenState extends State<HouseholdPromptScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
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
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: AppBar(
        title: Text(
          widget.isOptional ? 'Add Household' : 'Household Setup',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: widget.isOptional
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: RpgTheme.primaryGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.holiday_village_rounded,
                  size: 48,
                  color: RpgTheme.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.isOptional
                  ? 'Join or Create Household'
                  : 'Welcome, ${widget.user.name.split(' ').first}!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Chore bounties are shared among roommates. Choose whether to create a new apartment guild or join your roommates with an invite code.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TabBar(
                controller: tabController,
                indicatorColor: RpgTheme.primaryGreen,
                indicatorWeight: 3,
                labelColor: RpgTheme.primaryGreen,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.add_home_rounded), text: 'Create New'),
                  Tab(icon: Icon(Icons.vpn_key_rounded), text: 'Join by Code'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              height: 280,
              child: TabBarView(
                controller: tabController,
                children: [
                  _buildCreateTab(),
                  _buildJoinTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Household Name',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: createNameController,
            decoration: const InputDecoration(
              hintText: 'e.g. Apt 4B, Maple Street House',
              prefixIcon: Icon(Icons.house_outlined),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You will be designated as the Guild Owner and receive an invite code to share.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
          const Spacer(),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: RpgTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: isBusy ? null : handleCreate,
            icon: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: const Text(
              'Create Guild',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinTab() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Apartment Invite Code',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: joinCodeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'e.g. GUILD4B or APT4B123',
              prefixIcon: Icon(Icons.key_rounded),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask your roommate for their household invite code to join their chore board.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
          const Spacer(),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: RpgTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: isBusy ? null : handleJoin,
            icon: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.login_rounded),
            label: const Text(
              'Join Household',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
