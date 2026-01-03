import 'package:flutter/material.dart';
import 'package:fridge/utils/constants.dart';

Widget myTextForm({
  required String title,
  required FocusNode focusNode,
  required TapRegionCallback onTapOutside,
  required TextEditingController controller,
  IconData? icon,
  required String hintText,
  String? errorText,
  ValueChanged? onChanged,
  bool obscureText = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: .w500),
      ),
      const SizedBox(height: 8),
      mytextField(
        onTapOutside: onTapOutside,
        focusNode: focusNode,
        controller: controller,
        obscureText: obscureText,
        icon: icon,
        hintText: hintText,
        errorText: errorText,
        onChanged: onChanged,
      ),
    ],
  );
}

TextField mytextField({
  required TapRegionCallback onTapOutside,
  required FocusNode focusNode,
  required TextEditingController controller,
  bool obscureText = false,
  IconData? icon,
  required String hintText,
  String? errorText,
  ValueChanged<dynamic>? onChanged,
  TextInputType? keyboardType
}) {
  final prefixIcon = icon != null ? Icon(icon, color: colorsSecondary) : null;
  return TextField(
    onTapOutside: onTapOutside,
    focusNode: focusNode,
    controller: controller,
    obscureText: obscureText,
    decoration: InputDecoration(
      prefixIcon: prefixIcon,
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      border: textBorder,
      enabledBorder: textBorder,
      focusedBorder: textBorder,
      errorBorder: textErrorBorder,
      errorText: errorText,
    ),
    onChanged: onChanged,
  );
}
