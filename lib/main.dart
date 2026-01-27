import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:Eyeventory/firebase_options.dart';
import 'package:Eyeventory/screens/root.dart';
import 'package:Eyeventory/screens/inventory/add_item.dart';
import 'package:Eyeventory/screens/inventory/edit_item.dart';
import 'package:Eyeventory/screens/onboarding/welcome.dart';
import 'package:Eyeventory/screens/inventory/item_details.dart';

import 'package:Eyeventory/screens/auth/login.dart';
import 'package:Eyeventory/screens/auth/reset_password.dart';
import 'package:Eyeventory/screens/auth/signup.dart';
import 'package:Eyeventory/screens/auth/verify_email.dart';
import 'package:Eyeventory/services/firebase_services.dart';
import 'package:Eyeventory/screens/shared/splash_screen.dart';
import 'package:Eyeventory/services/notification_service.dart';
import 'package:Eyeventory/models/inventory_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init(); // Initialize Notifications
  runApp(const Fridge());
}

class Fridge extends StatelessWidget {
  const Fridge({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eyeventory',
      theme: ThemeData(
        splashFactory: NoSplash.splashFactory,
        scaffoldBackgroundColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/add-item': (context) => const AddItemScreen(),
        "/edit-item": (context) => const EditItemScreen(),
        "/item-details": (context) => const ItemDetailsScreen(),
        '/verify-email': (context) => const VerifyEmailScreen(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _minTimePassed = false;
  bool _isBootstrapComplete = false;
  User? _user;
  String? _userRole;
  List<InventoryItem>? _initialItems;

  @override
  void initState() {
    super.initState();
    _startBootstrap();
  }

  Future<void> _startBootstrap() async {
    // 1. Start Minimum Timer
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _minTimePassed = true);
      }
    });

    // 2. Fetch Auth State & Profile
    // We listen to the stream once. If it emits, we process.
    // However, StreamBuilder is usually better for *re*auth updates.
    // But for the initial Splash, we want to wait for the *first* valid state.

    // Let's use the Stream to get the user, then fetch the profile.
    FirebaseServices().idTokenChanges.listen((user) async {
      if (!mounted) return;

      // If logging out, update immediately
      if (user == null) {
        setState(() {
          _user = null;
          _userRole = null;
          _initialItems = null;
        });
        return;
      }

      // If logging in, fetch data FIRST
      try {
        final profile = await FirebaseServices().getUserProfile();
        String role = 'home';
        List<InventoryItem>? items;

        if (profile != null) {
          role = profile['role'] as String? ?? 'home';
        }

        // Prefetch Items for all users
        try {
          items = await FirebaseServices().getItems().first;
        } catch (_) {}

        if (mounted) {
          setState(() {
            _user = user;
            _userRole = role;
            _initialItems = items;
            _isBootstrapComplete = true;
          });
        }
      } catch (e) {
        // Fallback
        if (mounted) {
          setState(() {
            _user = user;
            _userRole = 'home';
            _isBootstrapComplete = true;
          });
        }
      }
    });

    // Trigger something if stream doesn't emit?
    // FirebaseAuth stream usually emits immediately.

    // Note: The timer runs concurrently.
  }

  @override
  Widget build(BuildContext context) {
    // Condition to keep showing Splash:
    // Timer NOT passed OR Bootstrap NOT complete (data loading)
    if (!_minTimePassed || !_isBootstrapComplete) {
      return const SplashScreen();
    }

    final user = _user;

    // Not logged in → show home/onboarding
    if (user == null) {
      return const WelcomeScreen();
    }

    // Logged in but email not verified → show verification screen
    if (!user.emailVerified) {
      return const VerifyEmailScreen();
    }

    // Logged in and verified → show app with pre-fetched role
    return Root(userRole: _userRole ?? 'home', initialItems: _initialItems);
  }
}
