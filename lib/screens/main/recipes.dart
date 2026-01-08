import 'package:flutter/material.dart';
import 'package:fridge/utils/constants.dart';
import 'package:fridge/widgets/widgets.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  String _filterMode = 'My Fridge'; // 'My Fridge' or 'Browse All'

  final List<Map<String, dynamic>> _favoriteMeals = [
    {
      'name': 'Creamy Tomato Pasta',
      'image': 'creamy_tomato_pasta.png',
      'is_favorite': true,
    },
    {
      'name': 'Crispy Chicken Tacos',
      'image': 'crispy_chicken_tacos.png',
      'is_favorite': true,
    },
    {
      'name': 'Berry Smoothie',
      'image': 'berry_smoothie.png',
      'is_favorite': true,
    },
  ];

  final List<Map<String, dynamic>> _recipeSuggestions = [
    {
      'name': 'Spicy Chicken Curry',
      'category': 'Dinner',
      'description':
          'A rich and aromatic chicken curry with tender chicken pieces, cooked in a blend of traditional spices.',
      'ingredients_available': '6/8 ingredients available',
      'image': 'spicy_chicken_curry.png',
      'is_favorite': true,
    },
    {
      'name': 'Avocado Toast with Poached Egg',
      'category': 'Breakfast',
      'description':
          'A healthy and quick breakfast idea featuring creamy avocado spread on toasted sourdough, topped with a perfectly poached egg.',
      'ingredients_available': '4/5 ingredients available',
      'image': 'avocado_toast.png',
      'is_favorite': true,
    },
    {
      'name': 'Fresh Garden Salad',
      'category': 'Lunch',
      'description':
          'A light and refreshing salad with crisp mixed greens, juicy cherry tomatoes, crunchy cucumbers, and a tangy vinaigrette.',
      'ingredients_available': '5/5 ingredients available',
      'image': 'garden_salad.png',
      'is_favorite': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: 'Search Recipes...',
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
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
                    // Filter Bar
                    Container(
                      padding: .symmetric(vertical: 3, horizontal: 7),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: colorsBorder),
                      ),
                      child: Row(
                        spacing: 5,
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _filterMode = 'My Fridge'),
                              style: TextButton.styleFrom(
                                backgroundColor: _filterMode == 'My Fridge'
                                    ? Colors.white
                                    : Colors.transparent,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  side: _filterMode == 'My Fridge'
                                      ? BorderSide(
                                          color: colorsBorder,
                                          width: .3,
                                        )
                                      : BorderSide(color: Colors.transparent),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'My Fridge',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: .w600,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _filterMode = 'Browse All'),
                              style: TextButton.styleFrom(
                                backgroundColor: _filterMode == 'Browse All'
                                    ? Colors.white
                                    : Colors.transparent,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: _filterMode == 'Browse All'
                                      ? BorderSide(
                                          color: colorsBorder,
                                          width: .3,
                                        )
                                      : BorderSide(color: Colors.transparent),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'Browse All',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: .w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

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
                    SizedBox(
                      height: 125,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _favoriteMeals.length,
                        itemBuilder: (context, index) {
                          final meal = _favoriteMeals[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 14.0),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    meal['image'] as String,
                                    width: 160,
                                    height: 180,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 160,
                                        height: 180,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Text('Image'),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black.withValues(
                                      alpha: 0.2,
                                    ),
                                    radius: 20,
                                    child: IconButton(
                                      padding: .zero,
                                      onPressed: () {
                                        setState(() {
                                          meal['is_favorite'] =
                                              !meal['is_favorite'];
                                        });
                                      },
                                      icon: Icon(
                                        meal['is_favorite'] == true
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: Colors.white,
                                        size: 19,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      meal['name'] as String,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Recipe Suggestions Section
                    const Text(
                      'Recipe Suggestions',
                      style: TextStyle(
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final recipe = _recipeSuggestions[index];
                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colorsBorder, width: .5),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.asset(
                                recipe['image'] as String,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 180,
                                    color: Colors.grey[200],
                                    child: const Center(child: Text('Image')),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withValues(
                                  alpha: 0.2,
                                ),
                                radius: 20,
                                child: IconButton(
                                  padding: .zero,
                                  onPressed: () {
                                    setState(() {
                                      recipe['is_favorite'] =
                                          !recipe['is_favorite'];
                                    });
                                  },
                                  icon: Icon(
                                    recipe['is_favorite'] == true
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Column(
                                crossAxisAlignment: .start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      recipe['name'] as String,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.0,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      recipe['category'] as String,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Positioned(
                            //   bottom: 8,
                            //   right: 8,
                            //   child:
                            // ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe['description'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    color: colorsPrimary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    recipe['ingredients_available'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorsPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }, childCount: _recipeSuggestions.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
