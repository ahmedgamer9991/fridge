class SpoonacularRecipe {
  final int id;
  final String title;
  final String image;
  final int usedIngredientCount;
  final int missedIngredientCount;
  final List<String> usedIngredients;
  final List<String> missedIngredients;

  SpoonacularRecipe({
    required this.id,
    required this.title,
    required this.image,
    required this.usedIngredientCount,
    required this.missedIngredientCount,
    required this.usedIngredients,
    required this.missedIngredients,
  });

  factory SpoonacularRecipe.fromJson(Map<String, dynamic> json) {
    var usedList = (json['usedIngredients'] as List?)
            ?.map((e) => e['name'] as String)
            .toList() ??
        [];
    var missedList = (json['missedIngredients'] as List?)
            ?.map((e) => e['name'] as String)
            .toList() ??
        [];

    return SpoonacularRecipe(
      id: json['id'] as int,
      title: json['title'] as String,
      image: json['image'] as String? ?? '',
      usedIngredientCount: json['usedIngredientCount'] as int? ?? 0,
      missedIngredientCount: json['missedIngredientCount'] as int? ?? 0,
      usedIngredients: List<String>.from(usedList),
      missedIngredients: List<String>.from(missedList),
    );
  }
}

class RecipeIngredient {
  final String name;
  final String original;
  final double amount;
  final String unit;
  final bool isInFridge;

  RecipeIngredient({
    required this.name,
    required this.original,
    required this.amount,
    required this.unit,
    required this.isInFridge,
  });

  RecipeIngredient copyWith({bool? isInFridge}) {
    return RecipeIngredient(
      name: name,
      original: original,
      amount: amount,
      unit: unit,
      isInFridge: isInFridge ?? this.isInFridge,
    );
  }

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String? ?? '',
      original: json['original'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      isInFridge: false, // Computed at runtime
    );
  }
}

class RecipeDetails {
  final int id;
  final String title;
  final String image;
  final int readyInMinutes;
  final int servings;
  final String summary;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;

  RecipeDetails({
    required this.id,
    required this.title,
    required this.image,
    required this.readyInMinutes,
    required this.servings,
    required this.summary,
    required this.ingredients,
    required this.instructions,
  });

  factory RecipeDetails.fromJson(Map<String, dynamic> json) {
    var ingredientsList = (json['extendedIngredients'] as List?)
            ?.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Parse instructions
    List<String> steps = [];
    var analyzedInstructions = json['analyzedInstructions'] as List?;
    if (analyzedInstructions != null && analyzedInstructions.isNotEmpty) {
      var stepsJson = analyzedInstructions[0]['steps'] as List?;
      if (stepsJson != null) {
        for (var step in stepsJson) {
          steps.add(step['step'] as String? ?? '');
        }
      }
    }

    // Fallback if analyzedInstructions is empty but instructions field has HTML text
    if (steps.isEmpty && json['instructions'] != null) {
      String rawInstructions = json['instructions'] as String;
      // Strip simple HTML tags and split by newline/periods
      rawInstructions = rawInstructions.replaceAll(RegExp(r'<[^>]*>'), '');
      steps = rawInstructions
          .split(RegExp(r'(?:\r?\n)+|\.\s+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return RecipeDetails(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      image: json['image'] as String? ?? '',
      readyInMinutes: json['readyInMinutes'] as int? ?? 0,
      servings: json['servings'] as int? ?? 0,
      summary: json['summary'] as String? ?? '',
      ingredients: ingredientsList,
      instructions: steps,
    );
  }
}
