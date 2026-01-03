import 'package:flutter/material.dart';
import 'package:fridge/services/firebase_services.dart';
import 'package:fridge/utils/constants.dart';
import 'package:fridge/screens/widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isEmailValid = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Reset Your Password'),
        elevation: 0.5,
        shadowColor: const Color.fromRGBO(0, 0, 0, 1),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              myTextForm(
                title: 'Email',
                focusNode: _focusNode,
                onTapOutside: (event) => _focusNode.unfocus(),
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

              const Spacer(flex: 1),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isEmailValid && !_isLoading
                      ? () async {
                          setState(() => _isLoading = true);
                          try {
                            await FirebaseServices().resetPassword(
                              _emailController.text.trim(),
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Password reset email sent"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          } on Exception catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorsPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // Match other buttons
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Reset", // ✅ Fixed spelling
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
