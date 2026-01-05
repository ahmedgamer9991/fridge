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
}
