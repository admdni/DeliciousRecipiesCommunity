import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

class DeliciousRecipesScreen extends StatefulWidget {
  @override
  _DeliciousRecipesScreenState createState() => _DeliciousRecipesScreenState();
}

class _DeliciousRecipesScreenState extends State<DeliciousRecipesScreen> {
  final String unsplashAccessKey = '';
  List<String> categories = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Dessert'];
  String selectedCategory = 'All';
  List<RecipePhoto> recipes = [];
  Set<String> likedPhotos = {};

  @override
  void initState() {
    super.initState();
    loadLikedPhotos();
    fetchRecipes();
  }

  Future<void> loadLikedPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      likedPhotos = prefs.getStringList('likedPhotos')?.toSet() ?? {};
    });
  }

  Future<void> saveLikedPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    print("Saving liked photos: $likedPhotos"); // Debugging line
    await prefs.setStringList('likedPhotos', likedPhotos.toList());
  }

  Future<void> fetchRecipes() async {
    final response = await http.get(
      Uri.parse(
          'https://api.unsplash.com/search/photos?query=${selectedCategory == 'All' ? 'food' : selectedCategory}&per_page=30'),
      headers: {'Authorization': 'Client-ID $unsplashAccessKey'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        recipes = (data['results'] as List)
            .map((item) => RecipePhoto.fromJson(item))
            .toList();
      });
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  void toggleLike(String id, String imageUrl) {
    setState(() {
      if (likedPhotos.contains(id)) {
        likedPhotos.remove(id);
      } else {
        likedPhotos.add(imageUrl); // Favoriye eklenen fotoğrafın URL'sini sakla
      }
    });
    saveLikedPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Foods'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ChoiceChip(
                    label: Text(categories[index]),
                    selected: selectedCategory == categories[index],
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = categories[index];
                        fetchRecipes();
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Flexible(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailScreen(
                          recipe: recipe,
                          isLiked: likedPhotos.contains(recipe.imageUrl),
                          onLikePressed: () =>
                              toggleLike(recipe.id, recipe.imageUrl),
                        ),
                      ),
                    );
                  },
                  child: RecipeCard(
                    recipe: recipe,
                    isLiked: likedPhotos.contains(recipe.imageUrl),
                    onLikePressed: () => toggleLike(recipe.id, recipe.imageUrl),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RecipePhoto {
  final String id;
  final String imageUrl;
  final String title;
  final String fullImageUrl;

  RecipePhoto(
      {required this.id,
      required this.imageUrl,
      required this.title,
      required this.fullImageUrl});

  factory RecipePhoto.fromJson(Map<String, dynamic> json) {
    return RecipePhoto(
      id: json['id'],
      imageUrl: json['urls']['regular'],
      fullImageUrl: json['urls']['full'],
      title: json['alt_description'] ?? 'Delicious Recipe',
    );
  }
}

class RecipeCard extends StatelessWidget {
  final RecipePhoto recipe;
  final bool isLiked;
  final VoidCallback onLikePressed;

  const RecipeCard({
    Key? key,
    required this.recipe,
    required this.isLiked,
    required this.onLikePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              recipe.imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: onLikePressed,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeDetailScreen extends StatelessWidget {
  final RecipePhoto recipe;
  final bool isLiked;
  final VoidCallback onLikePressed;

  const RecipeDetailScreen({
    Key? key,
    required this.recipe,
    required this.isLiked,
    required this.onLikePressed,
  }) : super(key: key);

  Future<void> _downloadImage(BuildContext context) async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      try {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir == null) {
          throw Exception('Unable to access external storage');
        }

        final taskId = await FlutterDownloader.enqueue(
          url: recipe.fullImageUrl,
          savedDir: externalDir.path,
          fileName: '${recipe.id}.jpg',
          showNotification: true,
          openFileFromNotification: true,
        );

        if (taskId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image download started')),
          );
        } else {
          throw Exception('Failed to start download');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Storage permission is required to download images')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              panEnabled: false,
              boundaryMargin: EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 3,
              child: Image.network(
                recipe.fullImageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text('Failed to load image',
                        style: TextStyle(color: Colors.red)),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                    size: 30,
                  ),
                  onPressed: onLikePressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
