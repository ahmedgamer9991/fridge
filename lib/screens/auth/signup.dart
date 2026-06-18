// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Eyeventory/widgets/widgets.dart';
import 'package:Eyeventory/utils/constants.dart';
import 'package:Eyeventory/utils/error_utils.dart';
import 'package:Eyeventory/services/firebase_services.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
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
      appBar: AppHeader(title: 'Sign Up'),
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

              // Name Field
              AppTextFormField(
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
              AppTextFormField(
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
              AppTextFormField(
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
                  Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('I\'m a Home User'),
                        value: 'home',
                        groupValue: _selectedRole,
                        onChanged: (value) =>
                            setState(() => _selectedRole = value),
                        activeColor: colorsPrimary,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<String>(
                        title: const Text('I\'m a Store Manager'),
                        value: 'store',
                        groupValue: _selectedRole,
                        onChanged: (value) =>
                            setState(() => _selectedRole = value),
                        activeColor: colorsPrimary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Sign Up',
                  isLoading: _isLoading,
                  onPressed:
                      _isNameValid &&
                          _isEmailValid &&
                          _isPasswordValid &&
                          _selectedRole != null
                      ? () async {
                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            await ref.read(firebaseServicesProvider).createAccount(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                              _nameController.text.trim(),
                              _selectedRole!,
                            );
                            await ref.read(firebaseServicesProvider).sendEmailVerification();

                            if (!context.mounted) return;
                            Navigator.pop(context);
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                            if (!context.mounted) return;
                            ErrorUtils.showErrorSnackBar(
                              context,
                              ErrorUtils.parseError(e),
                            );
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
