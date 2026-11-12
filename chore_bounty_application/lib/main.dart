import 'package:flutter/material.dart';
import 'core/api_client.dart';
import 'core/token_storage.dart';
import 'services/auth_service.dart';
import 'services/bounty_service.dart';
import 'services/household_service.dart';
import 'screens/auth_gate.dart';
import 'screens/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChoreBountyApp());
}

class ChoreBountyApp extends StatelessWidget {
  const ChoreBountyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final storage = TokenStorage();
    late final ApiClient api;
    late final AuthService auth;
    late final BountyService bounties;
    late final HouseholdService households;

    api = ApiClient(
      storage,
      onUnauthorized: () {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => WelcomeScreen(
              auth: auth,
              bounties: bounties,
              households: households,
            ),
          ),
          (route) => false,
        );
      },
    );
    auth = AuthService(api, storage);
    bounties = BountyService(api);
    households = HouseholdService(api);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'ChoreBounty',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF159653)),
        scaffoldBackgroundColor: const Color(0xFFFFFCF6),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFFFFFCF6),
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFF0EAE0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      home: AuthGate(
        auth: auth,
        bounties: bounties,
        households: households,
      ),
    );
  }
}
