import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Eyeventory/services/firebase_services.dart';
import 'package:Eyeventory/utils/constants.dart';
import 'package:Eyeventory/widgets/widgets.dart';
import 'package:Eyeventory/utils/error_utils.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
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
      appBar: AppHeader(title: 'Reset Your Password'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              AppTextFormField(
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
                            await ref.read(firebaseServicesProvider).resetPassword(
                              _emailController.text.trim(),
                            );
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Password reset email sent"),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          } catch (e) {
                            if (!context.mounted) return;
                            ErrorUtils.showErrorSnackBar(
                              context,
                              ErrorUtils.parseError(e),
                            );
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
