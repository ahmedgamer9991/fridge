import 'package:flutter/material.dart';
import 'package:Eyeventory/models/inventory_item.dart';
import 'package:Eyeventory/utils/constants.dart';
import 'package:Eyeventory/widgets/stat_card.dart';
import 'package:Eyeventory/utils/helpers.dart';

class StatsGrid extends StatelessWidget {
  final List<InventoryItem> items;
  final String selectedFilterKey;
  final Function(String)? onFilterSelected;

  const StatsGrid({
    super.key,
    required this.items,
    this.selectedFilterKey = 'all',
    this.onFilterSelected,
  });

  // Logic moved to AppHelpers

  @override
  Widget build(BuildContext context) {
    int totalItems = items.length;
    int expiringSoon = items
        .where((item) => item.status == 'Expiring Soon')
        .length;
    int lowStock = items.where((item) => AppHelpers.isLowStock(item)).length;
    int spoiled = items.where((item) => item.status == 'Spoiled').length;

    final stats = [
      {
        'label': 'Total Items',
        'value': '$totalItems',
        'icon': Icons.checklist,
        'color': colorsPrimary,
        'filterKey': 'all',
      },
      {
        'label': 'Expiring Soon',
        'value': '$expiringSoon',
        'icon': Icons.timer,
        'color': statusExpiring,
        'filterKey': 'expiring',
      },
      {
        'label': 'Low Stock',
        'value': '$lowStock',
        'icon': Icons.shopping_bag,
        'color': statusLowStock,
        'filterKey': 'low_stock',
      },
      {
        'label': 'Spoiled',
        'value': '$spoiled',
        'icon': Icons.cancel,
        'color': statusSpoiled,
        'filterKey': 'spoiled',
      },
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 14,
      children: stats.map((stat) {
        final isInteractive = onFilterSelected != null;
        final isActive =
            isInteractive && selectedFilterKey == stat['filterKey'];
        final baseColor = stat['color'] as Color;

        return StatCard(
          label: stat['label'] as String,
          value: stat['value'] as String,
          color: baseColor,
          isActive: isActive,
          onTap: isInteractive
              ? () {
                  if (selectedFilterKey == stat['filterKey'] &&
                      stat['filterKey'] != 'all') {
                    onFilterSelected!('all');
                  } else {
                    onFilterSelected!(stat['filterKey'] as String);
                  }
                }
              : null,
        );
      }).toList(),
    );
  }
}
