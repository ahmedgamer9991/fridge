import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fridge/firebase_options.dart';
import 'package:fridge/root.dart';
import 'package:fridge/screens/add_item.dart';
import 'package:fridge/screens/edit_item.dart';
import 'package:fridge/screens/home.dart';
import 'package:fridge/screens/item_details.dart';
import 'package:fridge/screens/login.dart';
import 'package:fridge/screens/reset_password.dart';
import 'package:fridge/screens/signup.dart';
import 'package:fridge/screens/verify_email.dart';
import 'package:fridge/services/firebase_services.dart';
import 'package:fridge/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const Fridge());
}

class Fridge extends StatelessWidget {
  const Fridge({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fridge',
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
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseServices().idTokenChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = snapshot.data;

        // Not logged in → show home/onboarding
        if (user == null) {
          return const HomeScreen();
        }

        // Logged in but email not verified → show verification screen
        if (!user.emailVerified) {
          return const VerifyEmailScreen();
        }

        // Logged in and email verified → show app
        return const Root();
      },
    );
  }
}
