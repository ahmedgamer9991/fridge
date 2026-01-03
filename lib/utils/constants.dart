import 'package:flutter/material.dart';

Color colorsPrimary = Color(0xFF00C853);
Color? colorsSecondary = Colors.grey[600];
Color? colorsBorder = Colors.grey[300];

OutlineInputBorder textBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(20),
  borderSide: BorderSide(color: colorsBorder!),
);
OutlineInputBorder textErrorBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(20),
  borderSide: BorderSide(color: Colors.red),
);
