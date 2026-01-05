import 'package:flutter/material.dart';
import 'package:fridge/utils/constants.dart';

class AppTextFormField extends StatelessWidget {
  final String title;
  final FocusNode focusNode;
  final TapRegionCallback onTapOutside;
  final TextEditingController controller;
  final IconData? icon;
  final String hintText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  const AppTextFormField({
    super.key,
    required this.title,
    required this.focusNode,
    required this.onTapOutside,
    required this.controller,
    required this.hintText,
    this.icon,
    this.errorText,
    this.onChanged,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        AppTextField(
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
}

class AppTextField extends StatelessWidget {
  final TapRegionCallback onTapOutside;
  final FocusNode focusNode;
  final TextEditingController controller;
  final bool obscureText;
  final IconData? icon;
  final String hintText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  const AppTextField({
    super.key,
    required this.onTapOutside,
    required this.focusNode,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.icon,
    this.errorText,
    this.onChanged,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: kItemPadding,
          vertical: 12,
        ),
      ),
      onChanged: onChanged,
      keyboardType: keyboardType,
    );
  }
}

class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const AppSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onTapOutside: (event) {
        focusNode.unfocus();
      },
      focusNode: focusNode,
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, color: colorsSecondary),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, color: colorsSecondary),
                onPressed: onClear,
              )
            : null,
        hintText: 'Search food items...',
        hintStyle: const TextStyle(color: colorsSecondary),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: kItemPadding,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
          borderSide: const BorderSide(color: colorsBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
          borderSide: const BorderSide(color: colorsBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kBorderRadius),
          borderSide: const BorderSide(color: colorsPrimary),
        ),
      ),
    );
  }
}
