import 'dart:convert';
import 'package:http/http.dart' as http;
import 'recipe_model.dart';

class RecipeService {
  final String apiKey = '';
  final String baseUrl = 'https://api.spoonacular.com/recipes';

  Future<List<Recipe>> getRandomRecipes({int number = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/random?apiKey=$apiKey&number=$number'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['recipes'] as List)
          .map((recipeJson) => Recipe.fromJson(recipeJson))
          .toList();
    } else {
      throw Exception('Failed to load random recipes');
    }
  }

  Future<List<Recipe>> getRecipesByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/informationBulk?apiKey=$apiKey&ids=${ids.join(",")}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Recipe.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  Future<List<Recipe>> getRecipesByCategory(String category,
      {int number = 20}) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/complexSearch?apiKey=$apiKey&type=$category&number=$number'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((recipeJson) => Recipe.fromJson(recipeJson))
          .toList();
    } else {
      throw Exception('Failed to load recipes by category');
    }
  }

  Future<List<Recipe>> searchRecipes(String query, {int number = 20}) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/complexSearch?apiKey=$apiKey&query=$query&number=$number'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((recipeJson) => Recipe.fromJson(recipeJson))
          .toList();
    } else {
      throw Exception('Failed to search recipes');
    }
  }

  Future<Recipe> getRecipeDetails(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id/information?apiKey=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('API Response for Recipe Details:');
      print(json.encode(data)); // Tüm API yanıtını yazdır
      return Recipe.fromJson(data);
    } else {
      throw Exception('Failed to load recipe details: ${response.statusCode}');
    }
  }
}
