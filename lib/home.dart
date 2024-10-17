import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:yemekapp/services/favorites_screen.dart';
import 'package:yemekapp/services/recipe_images.dart';
import 'package:yemekapp/services/recipe_list_screen.dart';
import 'package:yemekapp/services/recipe_videos.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<IconData> _icons = [
    Icons.food_bank,
    Icons.stream,
    Icons.video_library,
    Icons.save,
  ];

  final List<Widget> _screens = [
    RecipeListScreen(),
    DeliciousRecipesScreen(),
    FoodRecipeVideoScreen(),
    FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: _icons,
        activeIndex: _currentIndex,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.verySmoothEdge,
        leftCornerRadius: 32,
        rightCornerRadius: 32, // Rounded edges for a smoother look
        onTap: (index) => setState(() => _currentIndex = index),
        activeColor: Colors.blueGrey[800],
        inactiveColor: Colors.blueGrey[300],
        backgroundColor: Colors.white,
        iconSize: 30, // Increased icon size
        // Optional: Add a shadow to the bottom navigation bar
        elevation: 8,
      ),
    );
  }
}
