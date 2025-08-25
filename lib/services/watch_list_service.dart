import 'package:movielistsuggest/models/movie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:flutter/material.dart';

class WatchListService {
  // Singleton pattern
  static final WatchListService _instance = WatchListService._internal();
  factory WatchListService() => _instance;
  WatchListService._internal() {
    // Initialize by loading the watch list
    loadWatchList();
  }

  // In-memory cache of watchlist
  List<Movie> _watchList = [];

  // Stream controller to notify listeners of changes
  final ValueNotifier<List<Movie>> watchListNotifier =
      ValueNotifier<List<Movie>>([]);

  // Get all movies in watch list
  List<Movie> get watchList => List.unmodifiable(_watchList);

  // Check if a movie is in the watch list
  bool isInWatchList(int movieId) {
    return _watchList.any((m) => m.id == movieId);
  }

  // Add movie to watch list
  Future<bool> addMovie(Movie movie) async {
    // Check if movie already exists in watchlist
    if (isInWatchList(movie.id)) {
      debugPrint('Movie ${movie.title} already in watch list');
      return false;
    }

    _watchList.add(movie);
    _notifyListeners();
    await _saveToPrefs();
    debugPrint('Added ${movie.title} to watch list');
    return true;
  }

  // Remove movie from watch list
  Future<bool> removeMovie(int movieId) async {
    final initialLength = _watchList.length;
    final movieTitle =
        _watchList
            .firstWhere(
              (m) => m.id == movieId,
              orElse: () => Movie(id: 0, title: "Unknown"),
            )
            .title;

    _watchList.removeWhere((m) => m.id == movieId);

    if (_watchList.length != initialLength) {
      _notifyListeners();
      await _saveToPrefs();
      debugPrint('Removed $movieTitle from watch list');
      return true;
    }
    return false;
  }

  // Toggle movie in watch list (add if not present, remove if present)
  Future<bool> toggleMovie(Movie movie) async {
    if (isInWatchList(movie.id)) {
      return await removeMovie(movie.id);
    } else {
      return await addMovie(movie);
    }
  }

  // Private helper method to notify listeners of changes
  void _notifyListeners() {
    watchListNotifier.value = List.from(_watchList);
  }

  // Load watch list from storage
  Future<void> loadWatchList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final watchListJson = prefs.getStringList('watchList') ?? [];

      debugPrint('Loading ${watchListJson.length} movies from storage');

      _watchList = [];
      for (final jsonString in watchListJson) {
        try {
          final Map<String, dynamic> movieMap = jsonDecode(jsonString);
          final movie = Movie.fromJson(movieMap);
          _watchList.add(movie);
        } catch (e) {
          debugPrint('Error parsing movie JSON: $e');
        }
      }

      _notifyListeners();
      debugPrint('Successfully loaded ${_watchList.length} movies');
    } catch (e) {
      debugPrint('Error loading watch list: $e');
      _watchList = [];
      _notifyListeners();
    }
  }

  // Save watch list to storage
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> watchListJson = [];

      for (final movie in _watchList) {
        try {
          final Map<String, dynamic> movieMap = movie.toJson();
          final String jsonString = jsonEncode(movieMap);
          watchListJson.add(jsonString);
        } catch (e) {
          debugPrint('Error encoding movie ${movie.title}: $e');
        }
      }

      await prefs.setStringList('watchList', watchListJson);
      debugPrint('Saved ${watchListJson.length} movies to storage');
    } catch (e) {
      debugPrint('Error saving watch list: $e');
    }
  }

  // Clear all movies from watch list
  Future<void> clearWatchList() async {
    _watchList.clear();
    _notifyListeners();
    await _saveToPrefs();
    debugPrint('Watch list cleared');
  }

  // Sort watch list by criteria
  void sortWatchList(SortCriteria criteria) {
    switch (criteria) {
      case SortCriteria.titleAsc:
        _watchList.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortCriteria.titleDesc:
        _watchList.sort((a, b) => b.title.compareTo(a.title));
        break;
      case SortCriteria.ratingDesc:
        _watchList.sort((a, b) {
          final ratingA = a.voteAverage ?? 0.0;
          final ratingB = b.voteAverage ?? 0.0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case SortCriteria.dateDesc:
        _watchList.sort((a, b) {
          final dateA = a.releaseDate ?? '';
          final dateB = b.releaseDate ?? '';
          return dateB.compareTo(dateA);
        });
        break;
    }
    _notifyListeners();
    debugPrint('Watch list sorted by ${criteria.name}');
  }

  // Get watch list stats
  Map<String, dynamic> getStats() {
    final int totalMovies = _watchList.length;

    double averageRating = 0;
    int moviesWithRating = 0;

    for (final movie in _watchList) {
      if (movie.voteAverage != null) {
        averageRating += movie.voteAverage!;
        moviesWithRating++;
      }
    }

    if (moviesWithRating > 0) {
      averageRating /= moviesWithRating;
    }

    return {
      'totalMovies': totalMovies,
      'averageRating': averageRating,
      'moviesWithRating': moviesWithRating,
    };
  }
}

// Sort criteria for watch list
enum SortCriteria {
  titleAsc('Title (A-Z)'),
  titleDesc('Title (Z-A)'),
  ratingDesc('Highest Rating'),
  dateDesc('Newest First');

  final String name;
  const SortCriteria(this.name);
}
