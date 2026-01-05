import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fridge/services/firebase_services.dart';
import 'package:fridge/utils/constants.dart';
import 'package:fridge/widgets/widgets.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
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
      final isVerified = await FirebaseServices().isEmailVerified();
      if (isVerified) {
        // ✅ FIX: Force the stream in main.dart to update
        await FirebaseServices().refreshUserStream();
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
          _errorMessage = 'Error checking verification: $e';
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      await FirebaseServices().sendEmailVerification();
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
          _errorMessage = 'Failed to send email: ${_getFriendlyError(e)}';
        });
      }
    }
  }

  String _getFriendlyError(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('network')) return 'No internet connection';
    if (msg.contains('timeout')) return 'Request timed out';
    if (msg.contains('invalid-email')) return 'Invalid email address';
    return 'Please try again later';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent manual popping
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Sign out when the user tries to go back
        await FirebaseServices().signOut();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppHeader(
          title: 'Verify Email',
          leading: _emailVerified
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () async {
                    // ✅ FIX: Sign out instead of Navigator.pop
                    // This triggers the stream in main.dart to show the HomeScreen
                    await FirebaseServices().signOut();
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
                        ? 'Great! Your email has been verified. You\'ll be redirected to your FridgeMate dashboard shortly.'
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
