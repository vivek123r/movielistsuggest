import 'dart:async';
import 'package:flutter/material.dart';
import 'package:movielistsuggest/models/movie.dart';
import 'package:movielistsuggest/pages/MovieDetailspage.dart';
import 'package:movielistsuggest/pages/ProfilePage.dart';
import 'package:movielistsuggest/services/movie_api_service.dart';
import 'package:movielistsuggest/services/watch_list_service.dart';
import 'package:movielistsuggest/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final MovieApiService apiService = MovieApiService();
  final WatchListService _watchListService = WatchListService();
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();
  List<Movie> _searchResults = [];
  List<Movie> _popularMovies = [];
  List<Movie> _latestMovies = [];
  List<Movie> _popularTVShows = [];
  List<Movie> _similarMovies = [];
  bool isLoading = false;
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  
  // Search filters
  String? _selectedYear;
  String? _selectedLanguage;
  bool _showFilters = false;

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
    _loadPopularTVShows();
    _loadWatchlistAndSimilarMovies();
    _startAutoScroll();
    
    // Add listener to page controller
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }
  
  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_popularMovies.isNotEmpty && _pageController.hasClients) {
        int nextPage = _currentPage + 1;
        int totalPages = _popularMovies.take(5).length;
        
        if (nextPage >= totalPages) {
          // Jump to first page without animation
          _pageController.jumpToPage(0);
        } else {
          // Animate to next page
          _pageController.animateToPage(
            nextPage,
            duration: Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      }
    });
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
    _pageController.dispose();
    _autoScrollTimer?.cancel();
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

  Future<void> _loadPopularTVShows() async {
    try {
      final tvShows = await apiService.getPopularTVShows();
      print(tvShows);
      setState(() {
        _popularTVShows = tvShows;
      });
      print('Loaded ${tvShows.length} popular TV shows');
    } catch (e) {
      print('Error loading popular TV shows: $e');
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
      final results = await apiService.searchAll(
        query,
        year: _selectedYear,
        language: _selectedLanguage,
      );
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
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      child: _searchController.text.isNotEmpty
          ? Column(
              children: [
                SizedBox(height: 35),
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
                          hintText: 'Search movies & TV shows...',
                          backgroundColor: WidgetStateProperty.all(Colors.grey[850]?.withOpacity(0.4)),
                          textStyle: WidgetStateProperty.all(
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          hintStyle: WidgetStateProperty.all(
                            TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                          leading: const Icon(Icons.search, color: Colors.grey),
                          elevation: WidgetStateProperty.all(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
                          color: _showFilters ? Colors.blue : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                        tooltip: 'Filters',
                      ),
                    ],
                  ),
                ),
                // Filter dropdowns
                if (_showFilters)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedYear,
                            decoration: InputDecoration(
                              labelText: 'Year',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[850]?.withOpacity(0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            dropdownColor: Colors.grey[850],
                            style: TextStyle(color: Colors.white),
                            items: [
                              DropdownMenuItem(value: null, child: Text('Any Year', style: TextStyle(color: Colors.white))),
                              ...List.generate(50, (index) {
                                int year = DateTime.now().year - index;
                                return DropdownMenuItem(
                                  value: year.toString(),
                                  child: Text(year.toString(), style: TextStyle(color: Colors.white)),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedYear = value;
                              });
                              if (_searchController.text.isNotEmpty) {
                                performSearch();
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedLanguage,
                            decoration: InputDecoration(
                              labelText: 'Language',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.grey[850]?.withOpacity(0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            dropdownColor: Colors.grey[850],
                            style: TextStyle(color: Colors.white),
                            items: [
                              DropdownMenuItem(value: null, child: Text('Any Language', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'es', child: Text('Spanish', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'fr', child: Text('French', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'de', child: Text('German', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'it', child: Text('Italian', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'ja', child: Text('Japanese', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'ko', child: Text('Korean', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'zh', child: Text('Chinese', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'hi', child: Text('Hindi', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'pt', child: Text('Portuguese', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'ru', child: Text('Russian', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'ar', child: Text('Arabic', style: TextStyle(color: Colors.white))),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedLanguage = value;
                              });
                              if (_searchController.text.isNotEmpty) {
                                performSearch();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 20),
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Expanded(
                        child: _searchResults.isEmpty
                            ? Center(child: Text("No results found"))
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
                                      leading: movie.posterUrl.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: Image.network(
                                                movie.posterUrl,
                                                width: 50,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    width: 50,
                                                    height: 80,
                                                    color: Colors.grey[300],
                                                    child: Icon(Icons.movie, size: 30),
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
                                        icon: _watchListService.isInWatchList(movie.id)
                                            ? Icon(Icons.check_circle, color: Colors.green)
                                            : Icon(Icons.add_circle_outline),
                                        tooltip: _watchListService.isInWatchList(movie.id)
                                            ? 'Already in Watch List'
                                            : 'Add to Watch List',
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MovieDetailsPage(movie: movie),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
              ],
            )
          : Stack(
              children: [
                // Main scrollable content
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Featured Movie Section
                      if (_popularMovies.isNotEmpty)
                        _buildFeaturedMovieCarousel(),
                      
                      SizedBox(height: 24),
                                  
                                  // Popular Movies Section
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
                                  
                                  // Popular TV Shows Section
                                  if (_popularTVShows.isNotEmpty) ...[
                                    Text(
                                      "Popular TV Shows",
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
                                        itemCount: _popularTVShows.length,
                                        padding: EdgeInsets.symmetric(horizontal: 16),
                                        itemBuilder: (context, index) {
                                          final tvShow = _popularTVShows[index];
                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => MovieDetailsPage(movie: tvShow),
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
                                                      tvShow.posterUrl,
                                                      width: 120,
                                                      height: 160,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => Container(
                                                        width: 120,
                                                        height: 160,
                                                        color: Colors.grey[800],
                                                        child: Icon(Icons.tv, size: 50),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    tvShow.displayTitle,
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
                                  ],
                                  
                                  // Latest Movies Section
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
                                  
                                  // Movies you may like Section
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
                            ),
                
                // Search Bar Overlay (on top of carousel)
                Positioned(
                  top: 35,
                  left: 16,
                  right: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SearchBar(
                      controller: _searchController,
                      onSubmitted: (value) {
                        performSearch();
                      },
                      hintText: 'Search movies...',
                      backgroundColor: WidgetStateProperty.all(Colors.grey[700]?.withOpacity(0.3)),
                      textStyle: WidgetStateProperty.all(
                        const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      hintStyle: WidgetStateProperty.all(
                        TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                      leading: const Icon(Icons.search, color: Colors.grey),
                      elevation: WidgetStateProperty.all(0),
                    ),
                  ),
                ),
                
                // Profile Icon Button
                Positioned(
                  top: 35,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[800]?.withOpacity(0.7),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.account_circle, color: Colors.white, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFeaturedMovieCarousel() {
    final moviesToShow = _popularMovies.take(5).toList();
    
    return Container(
      height: 450,
      child: Stack(
        children: [
          // PageView for movies
          PageView.builder(
            controller: _pageController,
            itemCount: moviesToShow.length,
            itemBuilder: (context, index) {
              return _buildFeaturedMovie(moviesToShow[index]);
            },
          ),
          
          // Page Indicators (dots)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                moviesToShow.length,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedMovie(Movie movie) {
    return GestureDetector(
      onTap: () {
        // Stop auto-scroll when navigating
        _autoScrollTimer?.cancel();
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailsPage(movie: movie),
          ),
        ).then((_) {
          // Restart auto-scroll when returning
          _startAutoScroll();
        });
      },
      child: Container(
        margin: EdgeInsets.zero,
        child: Stack(
          children: [
            // Background Image with Hero animation
            Positioned.fill(
              child: Hero(
                tag: 'movie-${movie.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: Image.network(
                    movie.backdropUrl.isNotEmpty ? movie.backdropUrl : movie.posterUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[900],
                      child: Icon(Icons.movie, size: 100, color: Colors.grey[700]),
                    ),
                  ),
                ),
              ),
            ),
            
            // Gradient Overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.9),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            
            // Movie Info at Bottom
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Movie Title
                  Text(
                    movie.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  
                
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
