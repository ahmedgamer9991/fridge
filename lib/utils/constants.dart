import 'package:flutter/material.dart';

const Color colorsPrimary = Color(0xFF386641);
const Color colorsSecondary = Color(0xFF757575); // Colors.grey[600]
const Color colorsBorder = Color(0xFFE0E0E0); // Colors.grey[300]

const double kDefaultPadding = 24.0;
const double kItemPadding = 16.0;
const double kBorderRadius = 8.0;
const double kDefaultExpiryThreshold = 3.0;

OutlineInputBorder textBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(kBorderRadius),
  borderSide: const BorderSide(color: colorsBorder),
);
OutlineInputBorder textErrorBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(kBorderRadius),
  borderSide: const BorderSide(color: Colors.red),
);
// Status Colors
const Color statusFresh = Color(0xFF2E7D32);
const Color statusExpiring = Color(0xFFFF6F00);
const Color statusSpoiled = Color(0xFFD32F2F);
const Color statusLowStock = Color(0xFFE6C000);

// Item Categories
const List<String> itemCategories = [
  'Produce',
  'Dairy',
  'Meat',
  'Frozen',
  'Pantry',
  'Beverage',
];

// Item Units
const List<String> itemUnits = [
  'units',
  'g',
  'kg',
  'ml',
  'L',
  'oz',
  'lb',
  'pack',
];
