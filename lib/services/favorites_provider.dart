import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Eyeventory/models/recipe_models.dart';

class FavoritesNotifier extends StateNotifier<List<SpoonacularRecipe>> {
  static const _prefsKey = 'favorite_recipes';

  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKey);
      if (list != null) {
        state = list.map((item) {
          final Map<String, dynamic> jsonMap = json.decode(item);
          return SpoonacularRecipe.fromJson(jsonMap);
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading favorites from SharedPreferences: $e');
    }
  }

  Future<void> toggleFavorite(SpoonacularRecipe recipe) async {
    final exists = state.any((e) => e.id == recipe.id);
    List<SpoonacularRecipe> newState;
    if (exists) {
      newState = state.where((e) => e.id != recipe.id).toList();
    } else {
      newState = [...state, recipe];
    }
    state = newState;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = newState.map((item) {
        return json.encode({
          'id': item.id,
          'title': item.title,
          'image': item.image,
          'usedIngredientCount': item.usedIngredientCount,
          'missedIngredientCount': item.missedIngredientCount,
          'usedIngredients': item.usedIngredients.map((name) => {'name': name}).toList(),
          'missedIngredients': item.missedIngredients.map((name) => {'name': name}).toList(),
        });
      }).toList();
      await prefs.setStringList(_prefsKey, list);
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<SpoonacularRecipe>>((ref) {
  return FavoritesNotifier();
});
