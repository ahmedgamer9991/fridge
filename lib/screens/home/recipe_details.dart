import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Eyeventory/models/recipe_models.dart';
import 'package:Eyeventory/services/recipe_service.dart';
import 'package:Eyeventory/services/grocery_provider.dart';
import 'package:Eyeventory/services/favorites_provider.dart';
import 'package:Eyeventory/utils/constants.dart';

class RecipeDetailsScreen extends ConsumerWidget {
  final int recipeId;
  final String fallbackTitle;
  final String fallbackImage;

  const RecipeDetailsScreen({
    super.key,
    required this.recipeId,
    this.fallbackTitle = '',
    this.fallbackImage = '',
  });

  String _cleanHtml(String html) {
    // Strip HTML tags
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(recipeDetailsProvider(recipeId));
    final favoriteRecipes = ref.watch(favoritesProvider);
    final isFav = favoriteRecipes.any((e) => e.id == recipeId);

    return Scaffold(
      backgroundColor: Colors.white,
      body: detailsAsync.when(
        data: (recipe) {
          if (recipe == null) {
            return const Center(child: Text('Failed to load recipe details.'));
          }

          final missingIngredients = recipe.ingredients.where((i) => !i.isInFridge).toList();

          return CustomScrollView(
            slivers: [
              // Premium Recipe Header Banner
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: colorsPrimary,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.white,
                      ),
                      onPressed: () {
                        if (isFav) {
                          final existing = favoriteRecipes.firstWhere((e) => e.id == recipeId);
                          ref.read(favoritesProvider.notifier).toggleFavorite(existing);
                        } else {
                          final usedIngredients = recipe.ingredients
                              .where((i) => i.isInFridge)
                              .map((i) => i.name)
                              .toList();
                          final missedIngredients = recipe.ingredients
                              .where((i) => !i.isInFridge)
                              .map((i) => i.name)
                              .toList();
                          final spoonRecipe = SpoonacularRecipe(
                            id: recipe.id,
                            title: recipe.title,
                            image: recipe.image,
                            usedIngredientCount: usedIngredients.length,
                            missedIngredientCount: missedIngredients.length,
                            usedIngredients: usedIngredients,
                            missedIngredients: missedIngredients,
                          );
                          ref.read(favoritesProvider.notifier).toggleFavorite(spoonRecipe);
                        }
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      recipe.image.isNotEmpty
                          ? Image.network(
                              recipe.image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFallbackImage(),
                            )
                          : _buildFallbackImage(),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black45,
                              Colors.transparent,
                              Colors.black54,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Title
                      Text(
                        recipe.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time & Servings Info Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoTile(
                            Icons.timer_outlined,
                            '${recipe.readyInMinutes} min',
                            'Prep & Cook',
                          ),
                          _infoTile(
                            Icons.restaurant_menu_outlined,
                            '${recipe.servings} Servings',
                            'Yield',
                          ),
                          _infoTile(
                            Icons.check_circle_outline,
                            '${recipe.ingredients.length - missingIngredients.length}/${recipe.ingredients.length}',
                            'Ingredients',
                          ),
                        ],
                      ),
                      const Divider(height: 32, thickness: 1),

                      // Summary Section
                      if (recipe.summary.isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _cleanHtml(recipe.summary),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Ingredients Section Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ingredients',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          if (missingIngredients.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                for (final ing in missingIngredients) {
                                  ref.read(groceryListProvider.notifier).addItem(
                                        ing.name,
                                        '${ing.amount.toStringAsFixed(1)} ${ing.unit}',
                                      );
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Added ${missingIngredients.length} ingredients to Grocery List!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_shopping_cart, size: 16),
                              label: const Text('Add Missing'),
                              style: TextButton.styleFrom(
                                foregroundColor: colorsPrimary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Ingredients Checklist
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: recipe.ingredients.length,
                        itemBuilder: (context, index) {
                          final ingredient = recipe.ingredients[index];
                          return _buildIngredientRow(context, ref, ingredient);
                        },
                      ),

                      const SizedBox(height: 32),

                      // Instructions Section
                      const Text(
                        'Directions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (recipe.instructions.isEmpty)
                        Text(
                          'No step-by-step instructions provided. Enjoy cooking!',
                          style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                        )
                      else
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: recipe.instructions.length,
                          itemBuilder: (context, index) {
                            return _buildStepRow(index + 1, recipe.instructions[index]);
                          },
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading recipe: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(recipeDetailsProvider(recipeId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      'assets/recipe_placeholder.jpg',
      fit: BoxFit.cover,
    );
  }

  Widget _infoTile(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: colorsPrimary, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildIngredientRow(BuildContext context, WidgetRef ref, RecipeIngredient ingredient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ingredient.isInFridge ? Colors.green.withOpacity(0.06) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ingredient.isInFridge ? Colors.green.withOpacity(0.2) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          // Availability Indicator Icon
          Icon(
            ingredient.isInFridge ? Icons.check_circle : Icons.radio_button_unchecked,
            color: ingredient.isInFridge ? Colors.green : Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),

          // Ingredient details text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name[0].toUpperCase() + ingredient.name.substring(1),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    decoration: ingredient.isInFridge ? TextDecoration.none : TextDecoration.none,
                  ),
                ),
                if (ingredient.original.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      ingredient.original,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),

          // Action button if not in stock
          if (!ingredient.isInFridge)
            IconButton(
              icon: Icon(Icons.add_shopping_cart, color: colorsPrimary, size: 20),
              onPressed: () {
                ref.read(groceryListProvider.notifier).addItem(
                      ingredient.name,
                      '${ingredient.amount.toStringAsFixed(1)} ${ingredient.unit}',
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${ingredient.name} to Grocery List!')),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStepRow(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant step number bubble
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorsPrimary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: colorsPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Step instruction content
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
