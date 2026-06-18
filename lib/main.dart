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
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init(); // Initialize Notifications
  runApp(const ProviderScope(child: Fridge()));
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

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _minTimePassed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _minTimePassed = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const WelcomeScreen();
        }

        if (!user.emailVerified) {
          return const VerifyEmailScreen();
        }

        final profileAsync = ref.watch(userProfileProvider);
        final activeFridgeIdAsync = ref.watch(activeFridgeIdProvider);
        final inventoryAsync = ref.watch(inventoryItemsProvider);

        final profileReady = profileAsync.hasValue;
        final fridgeReady = activeFridgeIdAsync.hasValue;
        final inventoryReady = inventoryAsync.hasValue || inventoryAsync.hasError;

        if (!_minTimePassed || !profileReady || !fridgeReady || !inventoryReady) {
          return const SplashScreen();
        }

        return const Root();
      },
      loading: () => const SplashScreen(),
      error: (err, stack) => const WelcomeScreen(),
    );
  }
}
