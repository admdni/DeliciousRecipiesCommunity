import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:http/http.dart' as http;
import 'package:yemekapp/services/favorites_provider.dart';
import 'package:yemekapp/services/recipe_model.dart';
import 'package:yemekapp/services/recipe_service.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> favoritedRecipes = [];
  List<String> favoritedPhotos = [];
  List<String> favoritedVideos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadFavorites().then((_) => cleanInvalidVideos());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoritedPhotos = prefs.getStringList('likedPhotos') ?? [];
      favoritedVideos = prefs.getStringList('likedVideos') ?? [];
      favoritedRecipes = prefs.getStringList('likedRecipes') ?? [];
    });
    print('Loaded favorites:');
    print('Photos (${favoritedPhotos.length}):');
    for (var photo in favoritedPhotos) {
      print('Photo URL: $photo'); // Debugging line
    }
    print('Videos (${favoritedVideos.length}):');
    for (var video in favoritedVideos) {
      print('Video URL: $video');
    }
  }

  Future<void> cleanInvalidVideos() async {
    List<String> validVideos = [];
    for (String videoUrl in favoritedVideos) {
      try {
        final response = await http.head(Uri.parse(videoUrl));
        if (response.statusCode == 200) {
          validVideos.add(videoUrl);
        } else {
          print('Invalid video URL: $videoUrl');
        }
      } catch (e) {
        print('Error checking video URL: $videoUrl');
      }
    }

    if (validVideos.length != favoritedVideos.length) {
      setState(() {
        favoritedVideos = validVideos;
      });
      _saveFavoriteVideos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Favorites'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.menu_book), text: 'Recipes'),
            Tab(icon: Icon(Icons.photo), text: 'Photos'),
            Tab(icon: Icon(Icons.video_library), text: 'Videos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FavoriteRecipesTab(),
          _buildPhotosList(),
          _buildVideosList(),
        ],
      ),
    );
  }

  Widget _buildPhotosList() {
    return favoritedPhotos.isEmpty
        ? Center(child: Text('No favorited photos'))
        : GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.0,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: favoritedPhotos.length,
            itemBuilder: (context, index) {
              final photoUrl = favoritedPhotos[index];
              return Card(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      photoUrl, // Ensure this is a valid network URL
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading image: $photoUrl');
                        print('Error details: $error');
                        return Center(
                          child: Icon(Icons.error, color: Colors.red),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.delete, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            favoritedPhotos.removeAt(index);
                            _saveFavoritePhotos();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Future<void> _saveFavoritePhotos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('likedPhotos', favoritedPhotos);
  }

  Widget _buildVideosList() {
    return favoritedVideos.isEmpty
        ? Center(child: Text('No favorited videos'))
        : ListView.builder(
            itemCount: favoritedVideos.length,
            itemBuilder: (context, index) {
              return FavoriteVideoItem(
                videoUrl: favoritedVideos[index],
                onRemove: () {
                  setState(() {
                    favoritedVideos.removeAt(index);
                    _saveFavoriteVideos();
                  });
                },
              );
            },
          );
  }

  Future<void> _saveFavoriteVideos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('likedVideos', favoritedVideos);
  }
}

class FavoriteVideoItem extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onRemove;

  FavoriteVideoItem({required this.videoUrl, required this.onRemove});

  @override
  _FavoriteVideoItemState createState() => _FavoriteVideoItemState();
}

class _FavoriteVideoItemState extends State<FavoriteVideoItem> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController,
            autoPlay: false,
            looping: false,
          );
          _isLoading = false;
        });
      }).catchError((error) {
        print("Video yüklenirken hata oluştu: $error");
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          if (_isLoading)
            Container(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasError)
            Container(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    Text('Failed to load video'),
                    ElevatedButton(
                      child: Text('Retry'),
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _hasError = false;
                        });
                        _initializeVideoPlayer();
                      },
                    ),
                  ],
                ),
              ),
            )
          else
            AspectRatio(
              aspectRatio: _videoPlayerController.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            ),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: widget.onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FavoriteRecipesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final recipeService = RecipeService();

    return FutureBuilder<List<Recipe>>(
      future: recipeService.getRecipesByIds(favoritesProvider.getFavoriteIds()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('An error occurred: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No favorite recipes.'));
        } else {
          final recipes = snapshot.data!;
          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return ListTile(
                leading: Image.network(recipe.image,
                    width: 50, height: 50, fit: BoxFit.cover),
                title: Text(recipe.title),
                subtitle: Text('${recipe.readyInMinutes} mins'),
                trailing: IconButton(
                  icon: Icon(Icons.favorite, color: Colors.red),
                  onPressed: () {
                    favoritesProvider.toggleFavorite(recipe.id);
                  },
                ),
              );
            },
          );
        }
      },
    );
  }
}
