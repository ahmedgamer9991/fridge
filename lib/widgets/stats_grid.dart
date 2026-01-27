import 'package:flutter/material.dart';
import 'package:Eyeventory/models/inventory_item.dart';
import 'package:Eyeventory/utils/constants.dart';

class StatsGrid extends StatelessWidget {
  final List<InventoryItem> items;
  final String selectedFilterKey;
  final Function(String) onFilterSelected;

  const StatsGrid({
    super.key,
    required this.items,
    required this.selectedFilterKey,
    required this.onFilterSelected,
  });

  bool _isLowStock(InventoryItem item) {
    // Basic logic based on unit (mock logic)
    // You can refine this based on your preferences
    double quantity;
    try {
      quantity = double.parse(item.quantity);
    } catch (e) {
      return false; // Skip if quantity is not a number
    }

    final unit = item.unit;

    if (unit == 'units' || unit == 'pack') {
      return quantity <= 2;
    } else if (unit == 'g' || unit == 'ml') {
      return quantity <= 100;
    } else if (unit == 'kg' || unit == 'L') {
      return quantity <= 0.5;
    }
    return quantity <= 2;
  }

  @override
  Widget build(BuildContext context) {
    int totalItems = items.length;
    int expiringSoon = items
        .where((item) => item.status == 'Expiring Soon')
        .length;
    int lowStock = items.where(_isLowStock).length;
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
        final isActive = selectedFilterKey == stat['filterKey'];
        final baseColor = stat['color'] as Color;
        // Make active cards slightly more opaque/different if needed,
        // or keep design consistent. The provided image shows white cards
        // with colored numbers/icons, not full colored cards.
        // Wait, the previous code had full colored cards.
        // The NEW design image shows:
        // White cards with Colored Borders (or shadow/outline) and Colored Counts.
        // Let's match the NEW design (from the prompt image).

        return SizedBox(
          width: (MediaQuery.of(context).size.width - 48) / 2,
          height: 80,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Toggle filter
                if (selectedFilterKey == stat['filterKey'] &&
                    stat['filterKey'] != 'all') {
                  onFilterSelected('all');
                } else {
                  onFilterSelected(stat['filterKey'] as String);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? baseColor.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: baseColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                      spreadRadius: 2
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      stat['label'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat['value'] as String,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: baseColor,
                        height: 1.0, // Removes default vertical padding
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
