import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/modern_login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/modern_home_screen.dart';
import 'screens/pnr_input_screen.dart';
import 'screens/journey_clarity_screen.dart';
import 'screens/find_buddy_intro_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/buddy_match_screen.dart';
import 'screens/profile_creation_screen.dart';
import 'services/token_store.dart';
import 'widgets/offline_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenStore.load();
  runApp(const TrainBuddyApp());
}

class TrainBuddyApp extends StatelessWidget {
  const TrainBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrainBuddy',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      initialRoute: '/login',
      builder: (context, child) {
        // Wrap the entire app with the offline banner
        return OfflineBanner(child: child ?? const SizedBox.shrink());
      },
      routes: {
        '/login': (context) => const ModernLoginScreen(),
        '/login-classic': (context) => const LoginScreen(),
        '/home': (context) => const ModernHomeScreen(),
        '/home-classic': (context) => const HomeScreen(),
        '/pnr': (context) => const PnrInputScreen(),
        '/journey-clarity': (context) => const JourneyClarityScreen(),
        '/find-buddy-intro': (context) => const FindBuddyIntroScreen(),
        '/paywall': (context) => const PaywallScreen(),
        '/buddy-match': (context) => const BuddyMatchScreen(),
      },
    );
  }
}
