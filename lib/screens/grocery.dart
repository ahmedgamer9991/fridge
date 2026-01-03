import 'package:flutter/material.dart';
import 'package:fridge/utils/constants.dart';

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  // Mock data for "Ingredients from favorite meals"
  final List<Map<String, dynamic>> _favoriteMealItems = [
    {
      'name': 'Organic Milk',
      'quantity': '1 gallon',
      'image': 'organic_milk.png',
      'isChecked': false,
    },
    {
      'name': 'Fresh Strawberries',
      'quantity': '1 lb',
      'image': 'strawberries.png',
      'isChecked': false,
    },
    {
      'name': 'Ground Beef (90/10)',
      'quantity': '1.5 lbs',
      'image': 'ground_beef.png',
      'isChecked': true,
    },
  ];

  // Mock data for "Fridge items that are low-stock"
  final List<Map<String, dynamic>> _lowStockItems = [
    {
      'name': 'Eggs (Large)',
      'quantity': '1 dozen',
      'image': 'eggs.png',
      'isChecked': false,
    },
    {
      'name': 'Spinach',
      'quantity': '1 bag',
      'image': 'spinach.png',
      'isChecked': false,
    },
    {
      'name': 'Parmesan Cheese',
      'quantity': '1 block',
      'image': 'parmesan_cheese.png',
      'isChecked': false,
    },
    {
      'name': 'Unsalted Butter',
      'quantity': '1 lb',
      'image': 'butter.png',
      'isChecked': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Grocery List'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {},
          ),
        ],
        elevation: .5,
        shadowColor: .fromRGBO(0, 0, 0, 1),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Ingredients from favorite meals
              const Text(
                'Ingredients from favorite meals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 14),
              ..._favoriteMealItems.map(_buildGroceryItem).toList(),
              const SizedBox(height: 20),

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
              ..._lowStockItems.map(_buildGroceryItem).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroceryItem(Map<String, dynamic> item) {
    return Card(
      color: Colors.white,
      elevation: .3,
      shadowColor: Color.fromRGBO(0, 0, 0, 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorsBorder!),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Checkbox(
          value: item['isChecked'] as bool,
          onChanged: (value) {
            setState(() {
              item['isChecked'] = value;
            });
          },
          activeColor: colorsPrimary,
          checkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: colorsBorder!),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              child: Image.asset(
                item['image'] as String,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.food_bank_outlined,
                    color: colorsSecondary,
                    size: 24,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] as String,
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
                    item['quantity'] as String,
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
            // TODO: Remove item from list
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Removed ${item['name']}')));
          },
        ),
      ),
    );
  }
}
