import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Eyeventory/utils/constants.dart';
import 'package:Eyeventory/utils/helpers.dart';
import 'package:Eyeventory/widgets/widgets.dart';
import 'package:Eyeventory/services/grocery_provider.dart';
import 'package:Eyeventory/services/firebase_services.dart';

class GroceryScreen extends ConsumerStatefulWidget {
  final bool isStoreUser;
  const GroceryScreen({super.key, this.isStoreUser = false});

  @override
  ConsumerState<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends ConsumerState<GroceryScreen> {
  // Local state to keep track of checked/unchecked low stock items
  final Set<String> _checkedLowStockItems = {};

  // Local state to track low-stock items dismissed by user for the session
  final Set<String> _dismissedLowStockItems = {};

  @override
  Widget build(BuildContext context) {
    // Watch the active shopping/grocery list items from Riverpod
    final favoriteMealItems = ref.watch(groceryListProvider);

    // Watch real-time fridge inventory to calculate low stock items
    final inventoryAsync = ref.watch(inventoryItemsProvider);

    final lowStockItems = inventoryAsync.maybeWhen(
      data: (items) {
        return items
            .where((item) =>
                AppHelpers.isLowStock(item) &&
                !_dismissedLowStockItems.contains(item.name))
            .map((item) {
              // Convert InventoryItem to GroceryItem representation
              final mockupImage = AppHelpers.getItemImage(item.name);

              return GroceryItem(
                name: item.name,
                quantity: '${item.quantity} ${item.unit}',
                image: mockupImage,
                isChecked: _checkedLowStockItems.contains(item.name),
              );
            })
            .toList();
      },
      orElse: () => <GroceryItem>[],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppHeader(
        title: widget.isStoreUser ? 'Low Stock Items' : 'Grocery List',
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Ingredients from favorite meals (Home User only)
              if (!widget.isStoreUser) ...[
                const Text(
                  'Ingredients from favorite meals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 14),
                if (favoriteMealItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No ingredients added. Find recipes and add missing ingredients!',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                else
                  ...favoriteMealItems.map((item) => _buildGroceryItem(item, isLowStock: false)),
                const SizedBox(height: 20),
              ],

              // Section 2: Fridge items that are low-stock
              const Text(
                'Fridge items that are low-stock',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 14),
              
              if (lowStockItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    inventoryAsync.isLoading
                        ? 'Loading inventory...'
                        : 'Great! No items are currently low stock.',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                )
              else
                ...lowStockItems.map((item) => _buildGroceryItem(item, isLowStock: true)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroceryItem(GroceryItem item, {required bool isLowStock}) {
    return Card(
      color: Colors.white,
      elevation: .3,
      shadowColor: const Color.fromRGBO(0, 0, 0, 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorsBorder),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Checkbox(
          value: item.isChecked,
          onChanged: (value) {
            if (isLowStock) {
              setState(() {
                if (value == true) {
                  _checkedLowStockItems.add(item.name);
                } else {
                  _checkedLowStockItems.remove(item.name);
                }
              });
            } else {
              ref.read(groceryListProvider.notifier).toggleItem(item.name, value ?? false);
            }
          },
          activeColor: colorsPrimary,
          checkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: colorsBorder),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  AppHelpers.getItemImage(item.name),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.food_bank_outlined,
                      color: colorsSecondary,
                      size: 24,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.quantity,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () {
            if (isLowStock) {
              setState(() {
                _dismissedLowStockItems.add(item.name);
              });
            } else {
              ref.read(groceryListProvider.notifier).removeItem(item.name);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Removed ${item.name}')),
            );
          },
        ),
      ),
    );
  }
}
