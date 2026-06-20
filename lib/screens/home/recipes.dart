import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Eyeventory/utils/constants.dart';
import 'package:Eyeventory/widgets/widgets.dart';
import 'package:Eyeventory/models/recipe_models.dart';
import 'package:Eyeventory/services/recipe_service.dart';
import 'package:Eyeventory/screens/home/recipe_details.dart';
import 'package:Eyeventory/services/favorites_provider.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  String _filterMode = 'My Fridge'; // 'My Fridge' or 'Browse All'
  final TextEditingController _searchController = TextEditingController();
  
  // Search state
  List<SpoonacularRecipe> _searchResults = [];
  bool _isSearching = false;
  String _currentSearchQuery = '';
  Timer? _debounceTimer;



  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      if (query.trim().isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _currentSearchQuery = '';
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _currentSearchQuery = query;
    });

    try {
      final results = await ref.read(recipeServiceProvider).searchRecipes(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search error: $e')),
      );
    }
  }

  void _toggleFavorite(SpoonacularRecipe recipe) {
    ref.read(favoritesProvider.notifier).toggleFavorite(recipe);
  }

  @override
  Widget build(BuildContext context) {
    // Watch inventory recommendation provider
    final fridgeRecipesAsync = ref.watch(fridgeRecipesProvider);
    final favoriteRecipes = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppHeader(
        title: 'Recipes',
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Filter Bar
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 7),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: colorsBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _filterMode = 'My Fridge';
                                });
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: _filterMode == 'My Fridge'
                                    ? Colors.white
                                    : Colors.transparent,
                                foregroundColor: Colors.black,
                                elevation: _filterMode == 'My Fridge' ? 1 : 0,
                                shadowColor: Colors.black26,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'My Fridge',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _filterMode = 'Browse All';
                                });
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: _filterMode == 'Browse All'
                                    ? Colors.white
                                    : Colors.transparent,
                                foregroundColor: Colors.black,
                                elevation: _filterMode == 'Browse All' ? 1 : 0,
                                shadowColor: Colors.black26,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'Browse All',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Search input shown only in Browse All
                    if (_filterMode == 'Browse All') ...[
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search over 360,000 recipes...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorsBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorsPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Favorite Meals Section
                    const Text(
                      'Favorite Meals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildFavoritesList(favoriteRecipes),
                    
                    const SizedBox(height: 24),

                    // Section header for suggestions / search results
                    Text(
                      _filterMode == 'My Fridge' ? 'Fridge Matches' : 'Search Results',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Content loading logic based on mode
            if (_filterMode == 'My Fridge')
              _buildFridgeMatches(fridgeRecipesAsync, favoriteRecipes)
            else
              _buildBrowseResults(favoriteRecipes),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(List<SpoonacularRecipe> favoriteRecipes) {
    if (favoriteRecipes.isEmpty) {
      return Container(
        height: 110,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: const Text(
          'No favorites yet. Tap the heart icon on any recipe!',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: favoriteRecipes.length,
        itemBuilder: (context, index) {
          final recipe = favoriteRecipes[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailsScreen(
                    recipeId: recipe.id,
                    fallbackTitle: recipe.title,
                    fallbackImage: recipe.image,
                  ),
                ),
              );
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: recipe.image.isNotEmpty
                        ? Image.network(
                            recipe.image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, e, s) => _fallbackMealImage(),
                          )
                        : _fallbackMealImage(),
                  ),
                  // Dark bottom gradient overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                  // Title text
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFridgeMatches(AsyncValue<List<SpoonacularRecipe>> asyncRecipes, List<SpoonacularRecipe> favorites) {
    return asyncRecipes.when(
      data: (recipes) {
        if (recipes.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.kitchen_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No matches found. Add more ingredients to your fridge to see tailored recipe matches!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final recipe = recipes[index];
                return _buildRecipeCard(recipe, favorites);
              },
              childCount: recipes.length,
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('Error loading suggestions: $err'),
        ),
      ),
    );
  }

  Widget _buildBrowseResults(List<SpoonacularRecipe> favorites) {
    if (_isSearching) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            _currentSearchQuery.isEmpty
                ? 'Type in the search box to browse recipes'
                : 'No recipes found matching "$_currentSearchQuery"',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final recipe = _searchResults[index];
            return _buildRecipeCard(recipe, favorites);
          },
          childCount: _searchResults.length,
        ),
      ),
    );
  }

  Widget _buildRecipeCard(SpoonacularRecipe recipe, List<SpoonacularRecipe> favorites) {
    final isFav = favorites.any((e) => e.id == recipe.id);
    
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[150] ?? const Color(0xFFF0F0F0)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailsScreen(
                recipeId: recipe.id,
                fallbackTitle: recipe.title,
                fallbackImage: recipe.image,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: recipe.image.isNotEmpty
                      ? Image.network(
                          recipe.image,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _fallbackMealCardImage(),
                        )
                      : _fallbackMealCardImage(),
                ),
                // Favorite Button Overlay
                Positioned(
                  top: 12,
                  right: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    radius: 20,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _toggleFavorite(recipe),
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.grey[700],
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Show ingredient availability indicators (only for Fridge matches or if ingredient lists are populated)
                  if (_filterMode == 'My Fridge' || recipe.usedIngredients.isNotEmpty) ...[
                    Row(
                      children: [
                        // Used ingredients badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${recipe.usedIngredientCount} Used',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Missed ingredients badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: recipe.missedIngredientCount == 0
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                recipe.missedIngredientCount == 0
                                    ? Icons.celebration_outlined
                                    : Icons.shopping_bag_outlined,
                                color: recipe.missedIngredientCount == 0 ? Colors.green : Colors.orange,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                recipe.missedIngredientCount == 0
                                    ? 'Fully Stocked!'
                                    : '${recipe.missedIngredientCount} Missing',
                                style: TextStyle(
                                  color: recipe.missedIngredientCount == 0 ? Colors.green : Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (recipe.missedIngredients.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Missing: ${recipe.missedIngredients.take(3).join(", ")}${recipe.missedIngredients.length > 3 ? "..." : ""}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ] else ...[
                    // Standard subtitle if not matching fridge directly
                    Text(
                      'Tap to see ingredients and cooking steps',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackMealImage() {
    return Image.asset(
      'assets/recipe_placeholder.jpg',
      fit: BoxFit.cover,
    );
  }

  Widget _fallbackMealCardImage() {
    return Image.asset(
      'assets/recipe_placeholder.jpg',
      width: double.infinity,
      height: 180,
      fit: BoxFit.cover,
    );
  }
}
