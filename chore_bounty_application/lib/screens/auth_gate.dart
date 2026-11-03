import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/bounty_service.dart';
import '../services/household_service.dart';
import 'home_shell.dart';
import 'household_prompt_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.auth,
    required this.bounties,
    required this.households,
  });

  final AuthService auth;
  final BountyService bounties;
  final HouseholdService households;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<AppUser?> future;

  @override
  void initState() {
    super.initState();
    future = _restore();
  }

  Future<AppUser?> _restore() async {
    if (await widget.auth.storage.read() == null) return null;
    try {
      final user = await widget.auth.me();
      if (user.hasHouseholds) {
        final currentHouseholdId = await widget.auth.storage.readHouseholdId();
        if (currentHouseholdId == null ||
            !user.households.any((h) => h.id.toString() == currentHouseholdId)) {
          await widget.auth.storage.saveHouseholdId(
            user.households.first.id.toString(),
          );
        }
      }
      return user;
    } catch (_) {
      await widget.auth.storage.clear();
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppUser?>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (snapshot.data == null) {
        return WelcomeScreen(
          auth: widget.auth,
          bounties: widget.bounties,
          households: widget.households,
        );
      }

      final user = snapshot.data!;
      if (!user.hasHouseholds) {
        return HouseholdPromptScreen(
          auth: widget.auth,
          bounties: widget.bounties,
          households: widget.households,
          user: user,
        );
      }

      return HomeShell(
        auth: widget.auth,
        bounties: widget.bounties,
        households: widget.households,
        user: user,
      );
    },
  );
}
