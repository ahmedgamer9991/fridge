import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Eyeventory/utils/constants.dart';
import 'package:Eyeventory/widgets/widgets.dart';
import 'package:Eyeventory/services/firebase_services.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _focusNode1 = FocusNode();
  final _focusNode2 = FocusNode();

  bool _isEmailValid = true;
  bool _isPasswordValid = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _focusNode1.dispose();
    _focusNode2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,

      appBar: AppHeader(title: 'Log In'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 30),
              // App Title
              Center(
                child: Text(
                  'Eyeventory',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // Email Field
              AppTextFormField(
                title: 'Email',
                focusNode: _focusNode1,
                onTapOutside: (event) => _focusNode1.unfocus(),
                controller: _emailController,
                errorText: _isEmailValid ? null : 'Please enter a valid email',
                hintText: 'Enter your email',
                icon: Icons.email_outlined,
                onChanged: (value) {
                  setState(() {
                    _isEmailValid = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value);
                  });
                },
              ),

              const SizedBox(height: 20),

              // Password Field
              AppTextFormField(
                title: 'Password',
                focusNode: _focusNode2,
                onTapOutside: (event) => _focusNode2.unfocus(),
                controller: _passwordController,
                errorText: _isPasswordValid
                    ? null
                    : 'Password must be at least 6 characters',
                hintText: 'Enter your password',
                icon: Icons.lock_outline,
                obscureText: true,
                onChanged: (value) {
                  setState(() {
                    _isPasswordValid = value.length >= 6;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Log In Button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Log In',
                  isLoading: _isLoading,
                  onPressed: _isEmailValid && _isPasswordValid
                      ? () async {
                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            // 1. Sign In
                            await ref.read(firebaseServicesProvider).signIn(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );

                            // 2. Sign-in succeeded. AuthGate handles data loading
                            // behind the SplashScreen, so we just pop back.

                            if (!context.mounted) return;
                            Navigator.pop(context);
                          } catch (e) {
                            setState(() {
                              _isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }
                        }
                      : null,
                ),
              ),

              // Forgot Password & Create Account Links
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.center,
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/reset-password');
                      },
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(fontSize: 16, color: colorsPrimary),
                      ),
                    ),
                    // const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/signup');
                      },
                      child: Text(
                        'Create new account',
                        style: TextStyle(fontSize: 16, color: colorsPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
