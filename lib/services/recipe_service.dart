import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:Eyeventory/config/api_config.dart';
import 'package:Eyeventory/models/recipe_models.dart';
import 'package:Eyeventory/services/firebase_services.dart';

class RecipeService {
  final String _apiKey = ApiConfig.spoonacularApiKey;
  final String _baseUrl = ApiConfig.baseUrl;

  // In-memory cache structures to minimize API consumption
  final Map<String, List<SpoonacularRecipe>> _ingredientsCache = {};
  final Map<String, List<SpoonacularRecipe>> _searchCache = {};
  final Map<int, RecipeDetails> _detailsCache = {};

  /// Simplifies ingredient names for Spoonacular search (e.g. "Anchor Butter" -> "butter")
  static String cleanIngredientName(String name) {
    String clean = name.toLowerCase().trim();
    // Remove brackets, parentheses and content inside
    clean = clean.replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '');
    // Remove numbers and fractions
    clean = clean.replaceAll(RegExp(r'\b\d+/\d+\b|\b\d+\.?\d*\b'), '');
    // Remove punctuation
    clean = clean.replaceAll(RegExp(r'[,.\-_\/*&+]'), ' ');
    
    // Words to strip
    final wordsToStrip = [
      'organic', 'fresh', 'raw', 'sweet', 'large', 'small', 'medium',
      'bag', 'bottle', 'package', 'cup', 'can', 'whole', 'slice', 'sliced',
      'chopped', 'diced', 'ground', 'shredded', 'anchor', 'pure', 'standard',
      'normal', 'frozen', 'pack', 'piece', 'pieces', 'clove', 'cloves',
      'head', 'heads', 'bunch', 'bunches', 'lb', 'lbs', 'oz', 'gram', 'grams',
      'kg', 'kilogram', 'kilograms', 'ml', 'liter', 'liters', 'tbsp', 'tsp',
      'teaspoon', 'teaspoons', 'tablespoon', 'tablespoons', 'cans', 'carton',
      'ripe', 'unripe', 'test', 'brand', 'low fat', 'skimmed', 'salted', 'unsalted'
    ];
    
    for (var word in wordsToStrip) {
      clean = clean.replaceAll(RegExp('\\b$word\\b'), '');
    }
    
    // Clean up multiple spaces and trim
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean;
  }

  /// Search recipes matching fridge ingredients
  Future<List<SpoonacularRecipe>> searchByIngredients(List<String> ingredients) async {
    if (ingredients.isEmpty) return [];
    
    // Clean ingredients and filter out empty strings
    final cleaned = ingredients
        .map((e) => cleanIngredientName(e))
        .where((e) => e.isNotEmpty)
        .toList();
        
    if (cleaned.isEmpty) return [];
    
    // Sort to create a consistent cache key
    cleaned.sort();
    final cacheKey = cleaned.join(',');
    
    if (_ingredientsCache.containsKey(cacheKey)) {
      return _ingredientsCache[cacheKey]!;
    }

    final url = Uri.parse('$_baseUrl/recipes/findByIngredients'
        '?ingredients=${Uri.encodeComponent(cacheKey)}'
        '&number=15'
        '&ranking=1'
        '&apiKey=$_apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final recipes = data.map((json) => SpoonacularRecipe.fromJson(json)).toList();
        _ingredientsCache[cacheKey] = recipes;
        return recipes;
      } else {
        throw Exception('Failed to fetch recipes by ingredients: ${response.statusCode}');
      }
    } catch (e) {
      print('Spoonacular searchByIngredients error: $e');
      return [];
    }
  }

  /// Browse and search recipes globally
  Future<List<SpoonacularRecipe>> searchRecipes(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];

    if (_searchCache.containsKey(trimmed)) {
      return _searchCache[trimmed]!;
    }

    final url = Uri.parse('$_baseUrl/recipes/complexSearch'
        '?query=${Uri.encodeComponent(trimmed)}'
        '&number=15'
        '&apiKey=$_apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        
        // Map complex search result into SpoonacularRecipe (empty counts initially)
        final recipes = results.map((item) {
          return SpoonacularRecipe(
            id: item['id'] as int,
            title: item['title'] as String? ?? '',
            image: item['image'] as String? ?? '',
            usedIngredientCount: 0,
            missedIngredientCount: 0,
            usedIngredients: [],
            missedIngredients: [],
          );
        }).toList();
        
        _searchCache[trimmed] = recipes;
        return recipes;
      } else {
        throw Exception('Failed to search recipes globally: ${response.statusCode}');
      }
    } catch (e) {
      print('Spoonacular searchRecipes error: $e');
      return [];
    }
  }

  /// Get detailed recipe instructions
  Future<RecipeDetails?> getRecipeInformation(int id, List<String> currentFridgeIngredients) async {
    if (_detailsCache.containsKey(id)) {
      // Re-evaluate in-fridge status of ingredients based on current fridge items
      final cached = _detailsCache[id]!;
      final updatedIngredients = _evaluateFridgeIngredients(cached.ingredients, currentFridgeIngredients);
      return RecipeDetails(
        id: cached.id,
        title: cached.title,
        image: cached.image,
        readyInMinutes: cached.readyInMinutes,
        servings: cached.servings,
        summary: cached.summary,
        ingredients: updatedIngredients,
        instructions: cached.instructions,
      );
    }

    final url = Uri.parse('$_baseUrl/recipes/$id/information'
        '?includeNutrition=false'
        '&apiKey=$_apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final details = RecipeDetails.fromJson(data);
        
        // Evaluate in-fridge status
        final evaluatedIngredients = _evaluateFridgeIngredients(details.ingredients, currentFridgeIngredients);
        final finalDetails = RecipeDetails(
          id: details.id,
          title: details.title,
          image: details.image,
          readyInMinutes: details.readyInMinutes,
          servings: details.servings,
          summary: details.summary,
          ingredients: evaluatedIngredients,
          instructions: details.instructions,
        );

        _detailsCache[id] = finalDetails;
        return finalDetails;
      } else {
        throw Exception('Failed to fetch recipe info: ${response.statusCode}');
      }
    } catch (e) {
      print('Spoonacular getRecipeInformation error: $e');
      return null;
    }
  }

  /// Computes which ingredients are available in the fridge
  List<RecipeIngredient> _evaluateFridgeIngredients(
      List<RecipeIngredient> recipeIngredients, List<String> fridgeIngredients) {
    
    final cleanedFridge = fridgeIngredients
        .map((e) => cleanIngredientName(e))
        .where((e) => e.isNotEmpty)
        .toList();

    return recipeIngredients.map((ingredient) {
      final cleanedName = cleanIngredientName(ingredient.name);
      
      // Determine if ingredient matches any item in the fridge
      bool isInFridge = cleanedFridge.any((fridgeItem) {
        // Matches if cleaned fridge item name is found in the recipe ingredient name, or vice versa
        return cleanedName.contains(fridgeItem) || fridgeItem.contains(cleanedName);
      });

      return ingredient.copyWith(isInFridge: isInFridge);
    }).toList();
  }
}

// Riverpod Provider definitions
final recipeServiceProvider = Provider<RecipeService>((ref) {
  return RecipeService();
});

/// Automatically fetches recipes using the user's active fridge inventory list
final fridgeRecipesProvider = FutureProvider<List<SpoonacularRecipe>>((ref) async {
  final inventoryAsync = ref.watch(inventoryItemsProvider);
  
  return inventoryAsync.when(
    data: (items) async {
      // Map inventory item names
      final ingredientNames = items.map((item) => item.name).toList();
      if (ingredientNames.isEmpty) return [];
      
      return ref.read(recipeServiceProvider).searchByIngredients(ingredientNames);
    },
    loading: () => [],
    error: (err, stack) {
      print('fridgeRecipesProvider error: $err');
      return [];
    },
  );
});

/// Fetches detailed information for a specific recipe, passing down active fridge items to match against ingredients
final recipeDetailsProvider = FutureProvider.family<RecipeDetails?, int>((ref, recipeId) async {
  final inventoryAsync = ref.watch(inventoryItemsProvider);
  final fridgeIngredients = inventoryAsync.maybeWhen(
    data: (items) => items.map((e) => e.name).toList(),
    orElse: () => <String>[],
  );
  
  return ref.read(recipeServiceProvider).getRecipeInformation(recipeId, fridgeIngredients);
});
