class Recipe {
  final int id;
  final String title;
  final String image;
  final int? readyInMinutes;
  final int? servings;
  final int? calories;
  final List<String>? ingredients;
  final List<String>? instructions;

  Recipe({
    required this.id,
    required this.title,
    required this.image,
    this.readyInMinutes,
    this.servings,
    this.calories,
    this.ingredients,
    this.instructions,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    print('Raw JSON: $json'); // Debug için eklendi

    return Recipe(
      id: json['id'],
      title: json['title'] ?? 'Unknown Recipe',
      image: json['image'] ?? 'https://via.placeholder.com/150',
      readyInMinutes: json['readyInMinutes'],
      servings: json['servings'],
      calories: json['nutrition']?['nutrients']
          ?.firstWhere(
            (nutrient) => nutrient['name'] == 'Calories',
            orElse: () => {'amount': null},
          )['amount']
          ?.round(),
      ingredients: _parseIngredients(json),
      instructions: _parseInstructions(json),
    );
  }

  static List<String>? _parseIngredients(Map<String, dynamic> json) {
    var extendedIngredients = json['extendedIngredients'];
    if (extendedIngredients is List) {
      return extendedIngredients
          .map((ingredient) => ingredient['original'] as String)
          .toList();
    }
    return null;
  }

  static List<String>? _parseInstructions(Map<String, dynamic> json) {
    var analyzedInstructions = json['analyzedInstructions'];
    if (analyzedInstructions is List && analyzedInstructions.isNotEmpty) {
      var steps = analyzedInstructions[0]['steps'];
      if (steps is List) {
        return steps.map((step) => step['step'] as String).toList();
      }
    }
    return null;
  }
}
