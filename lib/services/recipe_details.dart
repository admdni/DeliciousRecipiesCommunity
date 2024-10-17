import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'favorites_provider.dart';
import 'recipe_model.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailScreen({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'recipe-img-${recipe.id}',
                    child: Image.network(
                      recipe.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: Colors.grey);
                      },
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7)
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RecipeInfoRow(recipe: recipe),
                  SizedBox(height: 20),
                  _buildSectionTitle(context, 'Ingredients'),
                  SizedBox(height: 10),
                  IngredientsList(ingredients: recipe.ingredients),
                  SizedBox(height: 20),
                  _buildSectionTitle(context, 'Instructions'),
                  SizedBox(height: 10),
                  InstructionsList(instructions: recipe.instructions),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          return FloatingActionButton.extended(
            onPressed: () {
              favoritesProvider.toggleFavorite(recipe.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    favoritesProvider.isFavorite(recipe.id)
                        ? 'Added to favorites'
                        : 'Removed from favorites',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(
              favoritesProvider.isFavorite(recipe.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
            label: Text(
              favoritesProvider.isFavorite(recipe.id)
                  ? 'Remove from Favorites'
                  : 'Add to Favorites',
            ),
            backgroundColor: Theme.of(context).primaryColor,
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(color: Colors.white),
      ),
    );
  }
}

class RecipeInfoRow extends StatelessWidget {
  final Recipe recipe;

  const RecipeInfoRow({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InfoItem(
            icon: Icons.access_time,
            label: '${recipe.readyInMinutes ?? "N/A"} min',
            color: Colors.blue,
          ),
          InfoItem(
            icon: Icons.person,
            label: '${recipe.servings ?? "N/A"} servings',
            color: Colors.green,
          ),
          InfoItem(
            icon: Icons.local_fire_department,
            label: '${recipe.calories ?? "N/A"} cal',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const InfoItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class IngredientsList extends StatelessWidget {
  final List<String>? ingredients;

  const IngredientsList({Key? key, required this.ingredients})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ingredients == null || ingredients!.isEmpty) {
      return Text('No ingredients available');
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: ingredients!.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child:
                  Text('${index + 1}', style: TextStyle(color: Colors.white)),
            ),
            title: Text(ingredients![index]),
          ),
        );
      },
    );
  }
}

class InstructionsList extends StatelessWidget {
  final List<String>? instructions;

  const InstructionsList({Key? key, required this.instructions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (instructions == null || instructions!.isEmpty) {
      return Text('No instructions available');
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: instructions!.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child:
                  Text('${index + 1}', style: TextStyle(color: Colors.white)),
            ),
            title: Text(instructions![index]),
          ),
        );
      },
    );
  }
}
