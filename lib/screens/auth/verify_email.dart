import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Eyeventory/services/firebase_services.dart';
import 'package:Eyeventory/utils/constants.dart';
import 'package:Eyeventory/widgets/widgets.dart';
import 'package:Eyeventory/utils/error_utils.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isLoading = true;
  bool _emailVerified = false;
  String? _errorMessage;
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();

    // Auto-check every 5 seconds (for cases where user verifies in another tab)
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && !_emailVerified) {
        _checkVerificationStatus();
      }
    });
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVerificationStatus() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _checkVerificationStatus();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final isVerified = await ref.read(firebaseServicesProvider).isEmailVerified();
      if (isVerified) {
        // ✅ FIX: Force the stream in main.dart to update
        await ref.read(firebaseServicesProvider).refreshUserStream();
        ref.invalidate(authChangesProvider);
      }
      if (mounted) {
        setState(() {
          _emailVerified = isVerified;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ErrorUtils.parseError(e);
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      await ref.read(firebaseServicesProvider).sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ErrorUtils.parseError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent manual popping
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Sign out when the user tries to go back
        await ref.read(firebaseServicesProvider).signOut();
      },
      child: Scaffold(
        appBar: AppHeader(
          title: 'Verify Email',
          leading: _emailVerified
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () async {
                    // ✅ FIX: Sign out instead of Navigator.pop
                    // This triggers the stream in main.dart to show the HomeScreen
                    await ref.read(firebaseServicesProvider).signOut();
                  },
                ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Loading state
                if (_isLoading) const CircularProgressIndicator(),

                // Email Icon
                if (!_isLoading)
                  Icon(
                    _emailVerified ? Icons.check_circle : Icons.email_outlined,
                    size: 80,
                    color: _emailVerified ? statusFresh : Colors.grey[600],
                  ),
                const SizedBox(height: 32),

                // Title
                if (!_isLoading)
                  Text(
                    _emailVerified ? 'Email Verified!' : 'Check Your Email',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 16),

                // Description
                if (!_isLoading)
                  Text(
                    _emailVerified
                        ? 'Great! Your email has been verified. You\'ll be redirected to your Eyeventory dashboard shortly.'
                        : 'We sent a verification link to your email address. Please click the link to verify your account.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 32),

                // Error Message
                if (_errorMessage != null && !_isLoading)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),

                // Action Buttons
                if (!_emailVerified && !_isLoading)
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _resendVerificationEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorsPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 32,
                          ),
                        ),
                        child: const Text('Resend Verification Email'),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _loadVerificationStatus,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 32,
                          ),
                        ),
                        child: const Text('Refresh Status'),
                      ),
                    ],
                  ),

                // Verification Success State
                if (_emailVerified && !_isLoading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(top: 24),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Almost there! Redirecting to your dashboard...',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
