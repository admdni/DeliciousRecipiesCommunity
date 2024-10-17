import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider with ChangeNotifier {
  Set<int> _favorites = {};

  Set<int> get favorites => _favorites;

  FavoritesProvider() {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favorites') ?? [];
    _favorites = favList.map((id) => int.parse(id)).toSet();
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = _favorites.map((id) => id.toString()).toList();
    await prefs.setStringList('favorites', favList);
  }

  bool isFavorite(int id) {
    return _favorites.contains(id);
  }

  void toggleFavorite(int id) {
    if (_favorites.contains(id)) {
      _favorites.remove(id);
    } else {
      _favorites.add(id);
    }
    _saveFavorites();
    notifyListeners();
  }

  List<int> getFavoriteIds() {
    return _favorites.toList();
  }
}
