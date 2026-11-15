import 'package:dio/dio.dart';
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
    final token = await widget.auth.storage.read();
    if (token == null || token.isEmpty) return null;

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
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await widget.auth.storage.clear();
        return null;
      }
      rethrow;
    }
  }

  void _retry() {
    setState(() {
      future = _restore();
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppUser?>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (snapshot.hasError) {
        return Scaffold(
          backgroundColor: const Color(0xFFFAF8F5),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 48,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to connect',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Check your connection and try again. Your session is still saved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _retry,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B8354),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(
                      'Retry',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
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
