import 'package:flutter/material.dart';
import 'package:fridge/screens/widgets.dart';
import 'package:fridge/utils/constants.dart';
import '../services/firebase_services.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _focusNode1 = FocusNode();
  final _focusNode2 = FocusNode();
  final _focusNode3 = FocusNode();

  String? _selectedRole; // 'home' or 'store'

  bool _isNameValid = true;
  bool _isEmailValid = true;
  bool _isPasswordValid = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _focusNode1.dispose();
    _focusNode2.dispose();
    _focusNode3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Sign Up'),
        elevation: .5,
        shadowColor: .fromRGBO(0, 0, 0, 1),
      ),
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
                  'FridgeMate',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // Name Field
              myTextForm(
                title: 'Name',
                focusNode: _focusNode1,
                onTapOutside: (event) => _focusNode1.unfocus(),
                controller: _nameController,
                icon: Icons.person_outline,
                hintText: 'Your full name',
                errorText: _isNameValid ? null : 'Please enter your full name',
                onChanged: (value) {
                  setState(() {
                    _isNameValid = value.trim().length >= 2;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Email Field
              myTextForm(
                title: 'Email',
                focusNode: _focusNode2,
                onTapOutside: (event) => _focusNode2.unfocus(),
                controller: _emailController,
                icon: Icons.email_outlined,
                hintText: 'your.email@example.com',
                errorText: _isEmailValid ? null : 'Please enter a valid email',
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
              myTextForm(
                title: 'Password',
                focusNode: _focusNode3,
                onTapOutside: (event) => _focusNode3.unfocus(),
                controller: _passwordController,
                icon: Icons.lock_outline,
                hintText: 'Create a strong password',
                errorText: _isPasswordValid
                    ? null
                    : 'Password must be at least 6 characters',
                obscureText: true,
                onChanged: (value) {
                  setState(() {
                    _isPasswordValid = value.length >= 6;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Account Role Radio Group
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Role',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: .w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<String>(
                    groupValue: _selectedRole,
                    onChanged: (value) => setState(() => _selectedRole = value),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('I\'m a Home User'),
                          value: 'home',
                          activeColor: colorsPrimary,
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<String>(
                          title: const Text('I\'m a Store Manager'),
                          value: 'store',
                          activeColor: colorsPrimary,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isNameValid &&
                          _isEmailValid &&
                          _isPasswordValid &&
                          _selectedRole != null &&
                          !_isLoading
                      ? () async {
                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            // TODO: Handle signup logic
                            await FirebaseServices().createAccount(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                              _nameController.text.trim(),
                              _selectedRole!,
                            );
                            // ✅ Send verification email automatically
                            await FirebaseServices().sendEmailVerification();

                            if (mounted) {
                              Navigator.pop(context);
                            }

                            // ✅ Navigate to verification screen instead of app
                            // Navigator.popUntil(context, (route) => route.isFirst);
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   SnackBar(
                            //     content: Text(
                            //       'Signing up as $_selectedRole user...',
                            //     ),
                            //   ),
                            // );
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(0, 200, 83, 1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    elevation: 1,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
