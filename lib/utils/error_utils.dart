import 'package:flutter/material.dart';
import 'package:fridge/core/errors/exceptions.dart';
import 'package:fridge/utils/constants.dart';

class ErrorUtils {
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static String parseError(dynamic error) {
    if (error is AppException) {
      return error.message;
    }
    // Fallback for unexpected errors
    return 'An unexpected error occurred. Please try again.';
  }
}
