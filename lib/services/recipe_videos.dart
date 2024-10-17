import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class FoodRecipeVideoScreen extends StatefulWidget {
  @override
  _FoodRecipeVideoScreenState createState() => _FoodRecipeVideoScreenState();
}

class _FoodRecipeVideoScreenState extends State<FoodRecipeVideoScreen>
    with TickerProviderStateMixin {
  final String pexelsApiKey = '';
  List<String> categories = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Dessert'];
  String selectedCategory = 'All';
  List<RecipeVideo> videos = [];
  Set<String> likedVideos = {};
  int currentVideoIndex = 0;
  late PageController _pageController;
  VideoPlayerController? _videoPlayerController;
  late AnimationController _animationController;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    loadLikedVideos();
    fetchVideos().catchError((error) {
      print('Error in initState: $error');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load videos. Please try again later.')),
        );
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoPlayerController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadLikedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      likedVideos = prefs.getStringList('likedVideos')?.toSet() ?? {};
    });
  }

  Future<void> saveLikedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('likedVideos', likedVideos.toList());
  }

  Future<void> fetchVideos() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.pexels.com/videos/search?query=${selectedCategory == 'All' ? 'food recipe' : '$selectedCategory recipe'}&per_page=100'),
        headers: {'Authorization': pexelsApiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['videos'] is List) {
          setState(() {
            videos = (data['videos'] as List)
                .map((item) => RecipeVideo.fromJson(item))
                .where((video) => video.videoUrl.isNotEmpty)
                .toList();
            videos.shuffle();
            if (videos.isNotEmpty) {
              initializeVideoPlayer(videos[0].videoUrl);
            }
          });
        } else {
          throw Exception('Invalid response format: videos is not a list');
        }
      } else {
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching videos: $e');
      throw Exception('Failed to load videos: $e');
    }
  }

  void initializeVideoPlayer(String videoUrl) {
    _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isPlaying = true;
        });
        _videoPlayerController?.play();
        _videoPlayerController?.setLooping(true);
      });
  }

  void togglePlayPause() {
    setState(() {
      if (_videoPlayerController?.value.isPlaying == true) {
        _videoPlayerController?.pause();
        _animationController.reverse();
        _isPlaying = false;
      } else {
        _videoPlayerController?.play();
        _animationController.forward();
        _isPlaying = true;
      }
    });
  }

  void toggleLike(String id, String videoUrl) {
    setState(() {
      if (likedVideos.contains(videoUrl)) {
        likedVideos.remove(videoUrl);
      } else {
        likedVideos.add(videoUrl);
      }
    });
    saveLikedVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildCategorySelector(),
            Expanded(
              child: videos.isEmpty
                  ? Center(child: SpinKitCubeGrid(color: Colors.white))
                  : PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: videos.length,
                      onPageChanged: (index) {
                        setState(() {
                          currentVideoIndex = index;
                          initializeVideoPlayer(videos[index].videoUrl);
                        });
                      },
                      itemBuilder: (context, index) {
                        final video = videos[index];
                        return _buildVideoItem(video);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: selectedCategory == categories[index],
              onSelected: (selected) {
                setState(() {
                  selectedCategory = categories[index];
                  fetchVideos();
                });
              },
              selectedColor: Colors.orange,
              backgroundColor: Colors.grey[800],
              labelStyle: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoItem(RecipeVideo video) {
    return GestureDetector(
      onTap: togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _videoPlayerController?.value.isInitialized == true
              ? VideoPlayer(_videoPlayerController!)
              : Center(child: SpinKitPulse(color: Colors.white)),
          _buildGradientOverlay(),
          _buildVideoInfo(video),
          _buildPlayPauseOverlay(),
          _buildLikeButton(video),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoInfo(RecipeVideo video) {
    return Positioned(
      bottom: 70,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            video.title,
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(video.userImageUrl),
                radius: 15,
              ),
              SizedBox(width: 8),
              Text(
                video.userInfo,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseOverlay() {
    return Center(
      child: AnimatedOpacity(
        opacity: _isPlaying ? 0.0 : 1.0,
        duration: Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            iconSize: 50,
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: togglePlayPause,
          ),
        ),
      ),
    );
  }

  Widget _buildLikeButton(RecipeVideo video) {
    return Positioned(
      bottom: 20,
      right: 16,
      child: IconButton(
        icon: Icon(
          likedVideos.contains(video.videoUrl)
              ? Icons.favorite
              : Icons.favorite_border,
          color: Colors.red,
          size: 30,
        ),
        onPressed: () => toggleLike(video.id, video.videoUrl),
      ),
    );
  }
}

class RecipeVideo {
  final String id;
  final String videoUrl;
  final String title;
  final String userInfo;
  final String userImageUrl;

  RecipeVideo({
    required this.id,
    required this.videoUrl,
    required this.title,
    required this.userInfo,
    required this.userImageUrl,
  });

  factory RecipeVideo.fromJson(Map<String, dynamic> json) {
    String extractTitle(String? url) {
      if (url == null || url.isEmpty) return 'Unknown Title';
      final parts = url.split('/');
      if (parts.isEmpty) return 'Unknown Title';
      return parts.last.replaceAll('-', ' ').capitalizeFirst();
    }

    return RecipeVideo(
      id: json['id'].toString(),
      videoUrl: json['video_files']?.isNotEmpty == true
          ? json['video_files'][0]['link'] ?? ''
          : '',
      title: extractTitle(json['url']),
      userInfo: json['user']?['name'] ?? 'Unknown User',
      userImageUrl: json['user']?['url'] ?? '',
    );
  }
}

extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + this.substring(1);
  }
}
