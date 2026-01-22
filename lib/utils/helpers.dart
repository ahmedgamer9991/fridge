import 'package:flutter/material.dart';
import 'package:fridge/utils/constants.dart';

class AppHelpers {
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

  // Stable hash code for Strings (since 'str'.hashCode is not stable across restarts in Dart)
  static int getHashCode(String key) {
    var hash = 0;
    for (var i = 0; i < key.length; i++) {
      hash = 31 * hash + key.codeUnitAt(i);
      // Keep it to 32-bit integer range if possible, or just let Dart handle it.
      // Notification IDs need to be 32-bit int.
      hash = hash & 0xFFFFFFFF;
    }
    // Handle int overflow for Dart (just ensure it fits)
    return hash;
  }
}
