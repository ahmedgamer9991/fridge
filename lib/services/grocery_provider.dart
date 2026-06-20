import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Eyeventory/utils/helpers.dart';

class GroceryItem {
  final String name;
  final String quantity;
  final String image;
  final bool isChecked;

  GroceryItem({
    required this.name,
    required this.quantity,
    required this.image,
    this.isChecked = false,
  });

  GroceryItem copyWith({
    String? name,
    String? quantity,
    String? image,
    bool? isChecked,
  }) {
    return GroceryItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      image: image ?? this.image,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'image': image,
      'isChecked': isChecked,
    };
  }

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
      image: json['image'] as String? ?? 'assets/img_placeholder.png',
      isChecked: json['isChecked'] as bool? ?? false,
    );
  }
}

class GroceryListNotifier extends StateNotifier<List<GroceryItem>> {
  static const _prefsKey = 'grocery_items';

  GroceryListNotifier() : super([]) {
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKey);
      if (list != null) {
        state = list.map((item) {
          final Map<String, dynamic> jsonMap = json.decode(item);
          return GroceryItem.fromJson(jsonMap);
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading grocery items: $e');
    }
  }

  Future<void> _saveItems(List<GroceryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = items.map((item) => json.encode(item.toJson())).toList();
      await prefs.setStringList(_prefsKey, list);
    } catch (e) {
      debugPrint('Error saving grocery items: $e');
    }
  }

  void addItem(String name, String quantity) {
    final lowerName = name.toLowerCase().trim();
    if (state.any((e) => e.name.toLowerCase().trim() == lowerName)) {
      return; // Avoid duplicates
    }
    
    // Choose mockup image based on simple keyword matches
    final mockupImage = AppHelpers.getItemImage(name);

    final newState = [
      ...state,
      GroceryItem(
        name: name,
        quantity: quantity,
        image: mockupImage,
        isChecked: false,
      ),
    ];
    
    state = newState;
    _saveItems(newState);
  }

  void toggleItem(String name, bool isChecked) {
    final newState = [
      for (final item in state)
        if (item.name == name) item.copyWith(isChecked: isChecked) else item
    ];
    
    state = newState;
    _saveItems(newState);
  }

  void removeItem(String name) {
    final newState = state.where((item) => item.name != name).toList();
    
    state = newState;
    _saveItems(newState);
  }
}

final groceryListProvider = StateNotifierProvider<GroceryListNotifier, List<GroceryItem>>((ref) {
  return GroceryListNotifier();
});
