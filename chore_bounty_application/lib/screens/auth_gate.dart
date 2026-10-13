import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/bounty_service.dart';
import 'home_shell.dart';
import 'welcome_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.auth, required this.bounties});
  final AuthService auth;
  final BountyService bounties;

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
      return await widget.auth.me();
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

      return snapshot.data == null
          ? WelcomeScreen(auth: widget.auth, bounties: widget.bounties)
          : HomeShell(
              auth: widget.auth,
              bounties: widget.bounties,
              user: snapshot.data!,
            );
    },
  );
}
