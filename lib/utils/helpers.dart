import 'package:flutter/material.dart';
import 'package:Eyeventory/models/inventory_item.dart';
import 'package:Eyeventory/utils/constants.dart';

class AppHelpers {
  static bool isLowStock(InventoryItem item) {
    try {
      final q = double.parse(item.quantity);
      if (item.unit == 'units' || item.unit == 'pack') return q <= 2;
      if (item.unit == 'g' || item.unit == 'ml') return q <= 100;
      if (item.unit == 'kg' || item.unit == 'L') return q <= 0.5;
      return q <= 2;
    } catch (_) {
      return false;
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case 'Fresh':
        return statusFresh;
      case 'Expiring Soon':
        return statusExpiring;
      case 'Spoiled':
        return statusSpoiled;
      default:
        return Colors.grey;
    }
  }

  static String formatExpiryDate(DateTime? date) {
    if (date == null) return 'No expiry date';

    final now = DateTime.now();
    // Reset time components for accurate day comparison
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(date.year, date.month, date.day);

    final daysUntilExpiry = expiry.difference(today).inDays;

    if (daysUntilExpiry < 0) {
      return 'Expired ${(-daysUntilExpiry).toString()} day${daysUntilExpiry == -1 ? '' : 's'} ago';
    } else if (daysUntilExpiry == 0) {
      return 'Expires today';
    } else if (daysUntilExpiry == 1) {
      return 'Expires tomorrow';
    } else if (daysUntilExpiry <= 7) {
      return 'Expires in $daysUntilExpiry days';
    } else {
      return 'Expires on ${date.day}/${date.month}/${date.year}';
    }
  }

  static String getItemImage(String name) {
    final lowerName = name.toLowerCase().trim();
    if (lowerName.contains('apple')) return 'assets/apple.jpg';
    if (lowerName.contains('banana')) return 'assets/banana.jpg';
    if (lowerName.contains('bread')) return 'assets/bread.jpg';
    if (lowerName.contains('carrot')) return 'assets/carrot.jpg';
    if (lowerName.contains('cucumber')) return 'assets/cucumber.jpg';
    if (lowerName.contains('egg')) return 'assets/egg.jpg';
    if (lowerName.contains('mango')) return 'assets/mango.jpg';
    if (lowerName.contains('orange')) return 'assets/orange.jpg';
    if (lowerName.contains('pepper')) return 'assets/pepper.jpg';
    if (lowerName.contains('potato')) return 'assets/potato.jpg';
    if (lowerName.contains('strawberry') || lowerName.contains('berry')) return 'assets/strawberry.jpg';
    if (lowerName.contains('tomato')) return 'assets/tomato.jpg';
    return 'assets/img_placeholder.png'; // default fallback
  }

  // Stable hash code for Strings (since 'str'.hashCode is not stable across restarts in Dart)
  static int getHashCode(String key) {
    var hash = 0;
    for (var i = 0; i < key.length; i++) {
      hash = 31 * hash + key.codeUnitAt(i);
      // Keep it to 32-bit integer range if possible, or just let Dart handle it.
      // Notification IDs need to be 32-bit int.
      hash = hash & 0xFFFFFFFF;
    }
    // Handle signed 32-bit int overflow for Flutter Local Notifications ID
    return hash.toSigned(32);
  }
}
