import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:movielistsuggest/models/movie.dart';

class MovieListData {
  final String id;
  final String name;
  final List<Movie> movies;
  final DateTime createdAt;
  final bool isDefault; // true for "My Watch List" and "Liked"

  MovieListData({
    required this.id,
    required this.name,
    required this.movies,
    required this.createdAt,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'movies': movies.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  factory MovieListData.fromJson(Map<String, dynamic> json) {
    return MovieListData(
      id: json['id'],
      name: json['name'],
      movies: (json['movies'] as List).map((m) => Movie.fromJson(m)).toList(),
      createdAt: DateTime.parse(json['createdAt']),
      isDefault: json['isDefault'] ?? false,
    );
  }

  MovieListData copyWith({
    String? id,
    String? name,
    List<Movie>? movies,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return MovieListData(
      id: id ?? this.id,
      name: name ?? this.name,
      movies: movies ?? this.movies,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class MovieListService extends ChangeNotifier {
  static final MovieListService _instance = MovieListService._internal();
  factory MovieListService() => _instance;
  MovieListService._internal();

  final Map<String, MovieListData> _lists = {};
  final Map<int, double> _movieRatings = {}; // Store user ratings (movieId -> rating)
  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;
  List<MovieListData> get allLists => _lists.values.toList()
    ..sort((a, b) {
      // Default lists first
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });
  
  MovieListData? getList(String id) => _lists[id];
  
  MovieListData? get watchList => _lists['watchlist'];
  MovieListData? get likedList => _lists['liked'];
  
  List<MovieListData> get customLists => _lists.values
      .where((list) => !list.isDefault)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<String> get allListNames => _lists.values.map((l) => l.name).toList();

  // Initialize all lists at app startup
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🎬 Initializing Movie List Service...');
    
    try {
      // Load from storage first
      await _loadFromStorage();
      
      bool needsSave = false;
      
      // Create default lists if they don't exist
      if (!_lists.containsKey('watchlist')) {
        _lists['watchlist'] = MovieListData(
          id: 'watchlist',
          name: 'My Watch List',
          movies: [],
          createdAt: DateTime.now(),
          isDefault: true,
        );
        needsSave = true;
        print('✨ Created default Watch List');
      }
      
      if (!_lists.containsKey('liked')) {
        _lists['liked'] = MovieListData(
          id: 'liked',
          name: 'Liked Movies',
          movies: [],
          createdAt: DateTime.now(),
          isDefault: true,
        );
        needsSave = true;
        print('✨ Created default Liked Movies list');
      }
      
      // Save if we created new default lists
      if (needsSave) {
        await _saveToStorage();
      }
      
      _isInitialized = true;
      notifyListeners();
      
      print('✅ Movie List Service initialized with ${_lists.length} lists');
      for (var list in _lists.values) {
        print('   - ${list.name}: ${list.movies.length} movies');
      }
    } catch (e) {
      print('❌ Error initializing Movie List Service: $e');
    }
  }

  // Load all lists from storage
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listsJson = prefs.getString('all_movie_lists');
      
      if (listsJson != null && listsJson.isNotEmpty) {
        final decoded = jsonDecode(listsJson) as Map<String, dynamic>;
        _lists.clear();
        decoded.forEach((key, value) {
          _lists[key] = MovieListData.fromJson(value);
        });
        print('📂 Loaded ${_lists.length} lists from storage');
      } else {
        print('📂 No existing lists found in storage');
      }

      // Load ratings
      final ratingsJson = prefs.getString('movie_ratings');
      if (ratingsJson != null && ratingsJson.isNotEmpty) {
        final decoded = jsonDecode(ratingsJson) as Map<String, dynamic>;
        _movieRatings.clear();
        decoded.forEach((key, value) {
          _movieRatings[int.parse(key)] = value as double;
        });
        print('⭐ Loaded ${_movieRatings.length} ratings from storage');
      }
    } catch (e) {
      print('❌ Error loading lists from storage: $e');
    }
  }

  // Save all lists to storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listsJson = jsonEncode(
        Map.fromEntries(_lists.entries.map((e) => MapEntry(e.key, e.value.toJson()))),
      );
      await prefs.setString('all_movie_lists', listsJson);
      
      // Save ratings
      final ratingsJson = jsonEncode(
        Map.fromEntries(_movieRatings.entries.map((e) => MapEntry(e.key.toString(), e.value))),
      );
      await prefs.setString('movie_ratings', ratingsJson);
      
      print('💾 Saved ${_lists.length} lists and ${_movieRatings.length} ratings to storage');
    } catch (e) {
      print('❌ Error saving lists to storage: $e');
    }
  }

  // Create a new custom list
  Future<String> createList(String name) async {
    final id = 'list_${DateTime.now().millisecondsSinceEpoch}';
    _lists[id] = MovieListData(
      id: id,
      name: name,
      movies: [],
      createdAt: DateTime.now(),
      isDefault: false,
    );
    await _saveToStorage();
    notifyListeners();
    print('✨ Created new list: $name');
    return id;
  }

  // Delete a custom list (cannot delete default lists)
  Future<bool> deleteList(String listId) async {
    if (_lists[listId]?.isDefault ?? true) {
      print('⚠️ Cannot delete default list');
      return false;
    }
    
    _lists.remove(listId);
    await _saveToStorage();
    notifyListeners();
    print('🗑️ Deleted list: $listId');
    return true;
  }

  // Rename a list
  Future<void> renameList(String listId, String newName) async {
    final list = _lists[listId];
    if (list != null) {
      _lists[listId] = list.copyWith(name: newName);
      await _saveToStorage();
      notifyListeners();
      print('✏️ Renamed list to: $newName');
    }
  }

  // Add movie to a specific list
  Future<void> addMovieToList(String listId, Movie movie) async {
    final list = _lists[listId];
    if (list != null) {
      // Check if movie already exists
      if (!list.movies.any((m) => m.id == movie.id)) {
        final updatedMovies = [...list.movies, movie];
        _lists[listId] = list.copyWith(movies: updatedMovies);
        await _saveToStorage();
        notifyListeners();
        print('➕ Added "${movie.title}" to "${list.name}"');
      } else {
        print('⚠️ Movie already exists in "${list.name}"');
      }
    }
  }

  // Remove movie from a specific list
  Future<void> removeMovieFromList(String listId, int movieId) async {
    final list = _lists[listId];
    if (list != null) {
      final updatedMovies = list.movies.where((m) => m.id != movieId).toList();
      _lists[listId] = list.copyWith(movies: updatedMovies);
      await _saveToStorage();
      notifyListeners();
      print('➖ Removed movie from "${list.name}"');
    }
  }

  // Toggle like (add/remove from liked list)
  Future<void> toggleLike(Movie movie) async {
    if (isInList('liked', movie.id)) {
      await removeMovieFromList('liked', movie.id);
    } else {
      await addMovieToList('liked', movie);
    }
  }

  // Check if movie is in a specific list
  bool isInList(String listId, int movieId) {
    return _lists[listId]?.movies.any((m) => m.id == movieId) ?? false;
  }

  // Get all lists containing a movie
  List<MovieListData> getListsContainingMovie(int movieId) {
    return _lists.values
        .where((list) => list.movies.any((m) => m.id == movieId))
        .toList();
  }

  // Clear all movies from a list
  Future<void> clearList(String listId) async {
    final list = _lists[listId];
    if (list != null) {
      _lists[listId] = list.copyWith(movies: []);
      await _saveToStorage();
      notifyListeners();
      print('🧹 Cleared list: ${list.name}');
    }
  }

  // Get list statistics
  Map<String, dynamic> getListStats(String listId) {
    final list = _lists[listId];
    if (list == null) return {'totalMovies': 0, 'averageRating': 0.0};

    final movies = list.movies;
    final totalMovies = movies.length;
    
    final ratingsSum = movies
        .where((m) => m.voteAverage != null && m.voteAverage! > 0)
        .fold(0.0, (sum, m) => sum + m.voteAverage!);
    
    final moviesWithRating = movies.where((m) => m.voteAverage != null && m.voteAverage! > 0).length;
    final averageRating = moviesWithRating > 0 ? ratingsSum / moviesWithRating : 0.0;

    return {
      'totalMovies': totalMovies,
      'averageRating': averageRating,
    };
  }

  // Get all movies from a specific list
  List<Movie> getMoviesFromList(String listId) {
    return _lists[listId]?.movies ?? [];
  }

  // Move movie from one list to another
  Future<void> moveMovie(Movie movie, String fromListId, String toListId) async {
    await removeMovieFromList(fromListId, movie.id);
    await addMovieToList(toListId, movie);
    print('🔄 Moved "${movie.title}" from "${_lists[fromListId]?.name}" to "${_lists[toListId]?.name}"');
  }

  // Copy movie to another list (doesn't remove from original)
  Future<void> copyMovie(Movie movie, String toListId) async {
    await addMovieToList(toListId, movie);
  }

  // Set user rating for a movie (0.0 to 10.0)
  Future<void> setMovieRating(int movieId, double rating) async {
    if (rating < 0.0 || rating > 10.0) {
      print('❌ Invalid rating: $rating. Must be between 0.0 and 10.0');
      return;
    }
    
    _movieRatings[movieId] = rating;
    await _saveToStorage();
    notifyListeners();
    print('⭐ Set rating for movie $movieId: $rating');
  }

  // Remove user rating for a movie
  Future<void> removeMovieRating(int movieId) async {
    _movieRatings.remove(movieId);
    await _saveToStorage();
    notifyListeners();
    print('🗑️ Removed rating for movie $movieId');
  }

  // Get user rating for a movie (returns null if not rated)
  double? getMovieRating(int movieId) {
    return _movieRatings[movieId];
  }

  // Check if movie has been rated by user
  bool isMovieRated(int movieId) {
    return _movieRatings.containsKey(movieId);
  }

  // Get all rated movies
  Map<int, double> get allRatings => Map.unmodifiable(_movieRatings);

  // Get average user rating for movies in a list
  double? getListAverageUserRating(String listId) {
    final list = _lists[listId];
    if (list == null || list.movies.isEmpty) return null;

    final ratedMovies = list.movies.where((m) => _movieRatings.containsKey(m.id));
    if (ratedMovies.isEmpty) return null;

    final sum = ratedMovies.fold(0.0, (total, m) => total + (_movieRatings[m.id] ?? 0.0));
    return sum / ratedMovies.length;
  }
}
