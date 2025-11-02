import 'package:flutter/material.dart';
import 'package:movielistsuggest/models/movie.dart';
import 'package:movielistsuggest/pages/MovieDetailspage.dart';
import 'package:movielistsuggest/services/movie_api_service.dart';
import 'package:movielistsuggest/services/watch_list_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final MovieApiService apiService = MovieApiService();
  final WatchListService _watchListService = WatchListService();
  List<Movie> _searchResults = [];
  List<Movie> _popularMovies = [];
  List<Movie> _latestMovies = [];
  List<Movie> _similarMovies = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add listener to search controller
    _searchController.addListener(() {
      // Clear results when search box is empty
      if (_searchController.text.isEmpty) {
        setState(() {
          _searchResults = [];
        });
      }
    });
    _loadPopularMovies();
    _getLatestMovies();
    _loadWatchlistAndSimilarMovies();
  }
  
  Future<void> _loadWatchlistAndSimilarMovies() async {
    // Wait for watchlist to load from storage
    await Future.delayed(Duration(seconds: 2));
    print('Watchlist count: ${_watchListService.watchList.length}');
    await _getSimilarMovies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  Future<void> _loadPopularMovies() async {
    try {
      final movies = await apiService.getPopularMovies();
      print(movies);
      setState(() {
        _popularMovies = movies;
      });
      print('Loaded ${movies.length} popular movies');
    } catch (e) {
      print('Error loading popular movies: $e');
    }
  }
  Future<void> _getLatestMovies() async {
      try {
        final movies = await apiService.getLatestMovies();
        print(movies);
        setState(() {
          _latestMovies = movies;
        });
        print('Loaded ${movies.length} latest movies');
      } catch (e) {
        print('Error loading latest movies: $e');
      }
  }
  Future<void> _getSimilarMovies() async {
    try {
      // Get all movies from watchlist
      final watchlistMovies = _watchListService.watchList;
      
      if (watchlistMovies.isEmpty) {
        print('Watchlist is empty, no similar movies to fetch');
        setState(() {
          _similarMovies = [];
        });
        return;
      }
      
      print('Fetching similar movies based on ${watchlistMovies.length} watchlist movies');
      
      List<Movie> allSimilarMovies = [];
      
      // Get similar movies for each movie in the watchlist (limit to first 5 to avoid too many API calls)
      final moviesToCheck = watchlistMovies.take(5).toList();
      
      for (final movie in moviesToCheck) {
        try {
          print('Fetching similar movies for: ${movie.title} (ID: ${movie.id})');
          final similarMovies = await apiService.getSimilarMovies(movie.id);
          print('Found ${similarMovies.length} similar movies for ${movie.title}');
          allSimilarMovies.addAll(similarMovies);
        } catch (e) {
          print('Error fetching similar movies for ${movie.title}: $e');
        }
      }
      
      // Remove duplicates based on movie ID
      final seen = <int>{};
      final uniqueMovies = allSimilarMovies.where((movie) {
        if (seen.contains(movie.id)) {
          return false;
        }
        seen.add(movie.id);
        return true;
      }).toList();
      
      // Shuffle and limit to 20 movies
      uniqueMovies.shuffle();
      final randomMovies = uniqueMovies.take(20).toList();
      
      setState(() {
        _similarMovies = randomMovies;
      });
      print('Loaded ${randomMovies.length} random similar movies from ${uniqueMovies.length} unique movies');
    } catch (e) {
      print('Error loading similar movies: $e');
      setState(() {
        _similarMovies = [];
      });
    }
  }
  Future<void> performSearch() async {
    setState(() {
      isLoading = true;
    });
    String query = _searchController.text;
    if (query.isNotEmpty) {
      final results = await apiService.searchMovies(query);
      setState(() {
        _searchResults = results;
        isLoading = false;
      });
    } else {
      setState(() {
        _searchResults = [];
        isLoading = false; // This was set to true, fixed to false
      });
    }
  }

  void addToWatchList(Movie movie) async {
    final added = await _watchListService.addMovie(movie);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? '${movie.title} added to watch list'
              : '${movie.title} is already in your watch list',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text("search for movies"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: SearchBar(
                    controller: _searchController,
                    onSubmitted: (value) {
                      performSearch();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: performSearch,
                  child: Icon(Icons.search),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                child:
                    _searchResults.isEmpty && _searchController.text.isNotEmpty
                        ? Center(child: Text("No results found"))
                        : _searchResults.isEmpty
                        ? SingleChildScrollView(
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Popular Movies",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                              SizedBox(
                                height: 220,
                                child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _popularMovies.length,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemBuilder: (context, index) {
                                  final movie = _popularMovies[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MovieDetailsPage(movie: movie),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 120,
                                      margin: EdgeInsets.only(right: 12),
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              movie.posterUrl,
                                              width: 120,
                                              height: 160,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 120,
                                                height: 160,
                                                color: Colors.grey[800],
                                                child: Icon(Icons.movie, size: 50),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            movie.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              ),
                              SizedBox(height: 24),
                              Text(
                                "Latest Movies",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              SizedBox(
                                height: 220,
                                child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _latestMovies.length,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemBuilder: (context, index) {
                                  final movie = _latestMovies[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MovieDetailsPage(movie: movie),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 120,
                                      margin: EdgeInsets.only(right: 12),
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              movie.posterUrl,
                                              width: 120,
                                              height: 160,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 120,
                                                height: 160,
                                                color: Colors.grey[800],
                                                child: Icon(Icons.movie, size: 50),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            movie.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              ),
                              SizedBox(height: 24),
                              Text(
                                "Movies you may like",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              SizedBox(
                                height: 220,
                                child: _similarMovies.isEmpty
                                ? Center(
                                    child: Text(
                                      'Add movies to watchlist to get recommendations',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _similarMovies.length,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemBuilder: (context, index) {
                                  final movie = _similarMovies[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MovieDetailsPage(movie: movie),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 120,
                                      margin: EdgeInsets.only(right: 12),
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              movie.posterUrl,
                                              width: 120,
                                              height: 160,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 120,
                                                height: 160,
                                                color: Colors.grey[800],
                                                child: Icon(Icons.movie, size: 50),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            movie.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final movie = _searchResults[index];
                            return Card(
                              elevation: 2,
                              margin: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(8),
                                leading:
                                    movie.posterUrl.isNotEmpty
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Image.network(
                                            movie.posterUrl,
                                            width: 50,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Container(
                                                width: 50,
                                                height: 80,
                                                color: Colors.grey[300],
                                                child: Icon(
                                                  Icons.movie,
                                                  size: 30,
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                        : Container(
                                          width: 50,
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: Icon(Icons.movie, size: 30),
                                        ),

                                title: Text(
                                  movie.title,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${movie.year} ${movie.voteAverage != null ? '• ⭐ ${movie.voteAverage!.toStringAsFixed(1)}' : ''}',
                                ),
                                trailing: IconButton(
                                  onPressed: () {
                                    addToWatchList(movie);
                                  },
                                  icon:
                                      _watchListService.isInWatchList(movie.id)
                                          ? Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                          : Icon(Icons.add_circle_outline),
                                  tooltip:
                                      _watchListService.isInWatchList(movie.id)
                                          ? 'Already in Watch List'
                                          : 'Add to Watch List',
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              MovieDetailsPage(movie: movie),
                                    ),
                                  );
                                },
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
