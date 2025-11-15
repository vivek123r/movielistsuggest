import 'package:tmdb_api/tmdb_api.dart';
import 'package:movielistsuggest/models/movie.dart';

class MovieApiService {
  // TMDb API credentials
  static const String apiKey = '304387f245f1d7ff2d351fe78b7b198f';
  static const String accessToken =
      'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIzMDQzODdmMjQ1ZjFkN2ZmMmQzNTFmZTc4YjdiMTk4ZiIsIm5iZiI6MTc1NTI4MjI0Ni4xMzY5OTk4LCJzdWIiOiI2ODlmN2I0Njc0OTUyZWI2MGNhNDRkNjkiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.pH4UQoWp6TfhK2YKnBrW-EIAK6EX0bGBKCtz1HNVOlI';
  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  // Create TMDB instance
  late TMDB tmdb;

  // Constructor to initialize TMDB
  MovieApiService() {
    tmdb = TMDB(
      ApiKeys(apiKey, accessToken),
      logConfig: ConfigLogger(showLogs: true, showErrorLogs: true),
      defaultLanguage: 'en-US',
    );
  }

  // Calculate Levenshtein distance (similarity) between two strings
  int _levenshteinDistance(String s1, String s2) {
    s1 = s1.toLowerCase();
    s2 = s2.toLowerCase();
    
    List<List<int>> dp = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        if (s1[i - 1] == s2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce((a, b) => a < b ? a : b);
        }
      }
    }

    return dp[s1.length][s2.length];
  }

  // Calculate similarity score (0-100, higher is better)
  double _calculateSimilarity(String query, String title) {
    final distance = _levenshteinDistance(query, title);
    final maxLength = query.length > title.length ? query.length : title.length;
    if (maxLength == 0) return 100.0;
    return ((maxLength - distance) / maxLength) * 100;
  }

  Future<List<Movie>> searchMovies(String query) async {
    if (query.isEmpty) return [];
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        // Use the tmdb_api package to search movies
        final result = await tmdb.v3.search.queryMovies(query);

        // Check if results exist
        if (result['results'] != null) {
          final List<dynamic> movieResults = result['results'];
          List<Movie> movies = movieResults.map((json) => Movie.fromJson(json)).toList();
          
          // Sort by similarity to query (fuzzy search)
          movies.sort((a, b) {
            double similarityA = _calculateSimilarity(query, a.title);
            double similarityB = _calculateSimilarity(query, b.title);
            return similarityB.compareTo(similarityA); // Higher similarity first
          });
          
          print('Found ${movies.length} results for "$query", sorted by relevance');
          return movies;
        } else {
          print('No results found');
        }
      } catch (e) {
        if (attempt < 2) await Future.delayed(Duration(milliseconds: 500));
        else {
          print('Error searching movies: $e');
          return [];
        }
      }
    }
    return [];
  }
  
  // Get popular movies
  Future<List<Movie>> getPopularMovies({int page = 1}) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        print('Fetching popular movies, attempt ${attempt + 1}');
        
        final result = await tmdb.v3.movies.getPopular(page: page);

        if (result['results'] != null) {
          final List<dynamic> movieResults = result['results'];
          print('Found ${movieResults.length} popular movies');
          return movieResults.map((json) => Movie.fromJson(json)).toList();
        } else {
          print('No popular movies found');
        }
      } catch (e) {
        print('Error fetching popular movies on attempt ${attempt + 1}: $e');
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 1000));
        } else {
          print('All attempts failed for popular movies');
          return [];
        }
      }
    }
    return [];
  }

  // Get top rated movies
  Future<List<Movie>> getTopRatedMovies({int page = 1}) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        print('Fetching top rated movies, attempt ${attempt + 1}');
        
        final result = await tmdb.v3.movies.getTopRated(page: page);

        if (result['results'] != null) {
          final List<dynamic> movieResults = result['results'];
          print('Found ${movieResults.length} top rated movies');
          return movieResults.map((json) => Movie.fromJson(json)).toList();
        } else {
          print('No top rated movies found');
        }
      } catch (e) {
        print('Error fetching top rated movies on attempt ${attempt + 1}: $e');
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 1000));
        } else {
          print('All attempts failed for top rated movies');
          return [];
        }
      }
    }
    return [];
  }

  // Get now playing movies
  Future<List<Movie>> getNowPlayingMovies({int page = 1}) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        print('Fetching now playing movies, attempt ${attempt + 1}');
        
        final result = await tmdb.v3.movies.getNowPlaying(page: page);

        if (result['results'] != null) {
          final List<dynamic> movieResults = result['results'];
          print('Found ${movieResults.length} now playing movies');
          return movieResults.map((json) => Movie.fromJson(json)).toList();
        } else {
          print('No now playing movies found');
        }
      } catch (e) {
        print('Error fetching now playing movies on attempt ${attempt + 1}: $e');
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 1000));
        } else {
          print('All attempts failed for now playing movies');
          return [];
        }
      }
    }
    return [];
  }

  // Get upcoming movies
  // Get upcoming movies
Future<List<Movie>> getLatestMovies({int page = 1}) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        print('Fetching latest movies, attempt ${attempt + 1}');
        
        final result = await tmdb.v3.movies.getUpcoming(page: page);

        if (result['results'] != null) {
          final List<dynamic> movieResults = result['results'];
          print('Found ${movieResults.length} latest movies');
          return movieResults.map((json) => Movie.fromJson(json)).toList();
        } else {
          print('No latest movies found');
        }
      } catch (e) {
        print('Error fetching latest movies on attempt ${attempt + 1}: $e');
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 1000));
        } else {
          print('All attempts failed for latest movies');
          return [];
        }
      }
    }
    return [];
  }
  Future<List<Movie>> getSimilarMovies(int movieId, {int page = 1}) async {
  for (int attempt = 0; attempt < 3; attempt++) {
    try {
      print('Fetching similar movies for $movieId, attempt ${attempt + 1}');
      
      final result = await tmdb.v3.movies.getSimilar(movieId, page: page);

      if (result['results'] != null) {
        final List<dynamic> movieResults = result['results'];
        print('Found ${movieResults.length} similar movies');
        return movieResults.map((json) => Movie.fromJson(json)).toList();
      } else {
        print('No similar movies found');
      }
    } catch (e) {
      print('Error fetching similar movies on attempt ${attempt + 1}: $e');
      if (attempt < 2) {
        await Future.delayed(Duration(milliseconds: 1000));
      } else {
        print('All attempts failed for similar movies');
        return [];
      }
    }
  }
  return [];
}

  // ============ TV SHOWS ============
  
  // Get popular TV shows
  Future<List<Movie>> getPopularTVShows({int page = 1}) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        print('Fetching popular TV shows, attempt ${attempt + 1}');
        
        final result = await tmdb.v3.tv.getPopular(page: page);

        if (result['results'] != null) {
          final List<dynamic> tvResults = result['results'];
          print('Found ${tvResults.length} popular TV shows');
          return tvResults.map((json) {
            json['media_type'] = 'tv';
            return Movie.fromJson(json);
          }).toList();
        }
      } catch (e) {
        print('Error fetching popular TV shows on attempt ${attempt + 1}: $e');
        if (attempt < 2) await Future.delayed(Duration(milliseconds: 1000));
      }
    }
    return [];
  }

  // Get top rated TV shows
  Future<List<Movie>> getTopRatedTVShows({int page = 1}) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final result = await tmdb.v3.tv.getTopRated(page: page);
        if (result['results'] != null) {
          final List<dynamic> tvResults = result['results'];
          return tvResults.map((json) {
            json['media_type'] = 'tv';
            return Movie.fromJson(json);
          }).toList();
        }
      } catch (e) {
        if (attempt < 2) await Future.delayed(Duration(milliseconds: 1000));
      }
    }
    return [];
  }

  // Get trending (movies + TV shows)
  Future<List<Movie>> getTrending({String timeWindow = 'week', int page = 1}) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        print('Fetching trending content, attempt ${attempt + 1}');
        
        // Convert string to TimeWindow enum
        final window = timeWindow == 'day' ? TimeWindow.day : TimeWindow.week;
        
        final result = await tmdb.v3.trending.getTrending(page: page, timeWindow: window);

        if (result['results'] != null) {
          final List<dynamic> results = result['results'];
          print('Found ${results.length} trending items');
          return results.map((json) => Movie.fromJson(json)).toList();
        }
      } catch (e) {
        print('Error fetching trending on attempt ${attempt + 1}: $e');
        if (attempt < 2) await Future.delayed(Duration(milliseconds: 1000));
      }
    }
    return [];
  }

  // Search movies AND TV shows
  Future<List<Movie>> searchAll(String query, {String? year, String? language}) async {
    if (query.isEmpty) return [];
    
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        // Search both movies and TV shows
        final movieResults = await tmdb.v3.search.queryMovies(
          query,
          year: year != null ? int.tryParse(year) : null,
          language: language,
        );
        final tvResults = await tmdb.v3.search.queryTvShows(
          query,
          firstAirDateYear: year,
          language: language,
        );

        List<Movie> allResults = [];
        
        if (movieResults['results'] != null) {
          final List<dynamic> movies = movieResults['results'];
          allResults.addAll(movies.map((json) {
            json['media_type'] = 'movie';
            return Movie.fromJson(json);
          }));
        }
        
        if (tvResults['results'] != null) {
          final List<dynamic> tvShows = tvResults['results'];
          allResults.addAll(tvShows.map((json) {
            json['media_type'] = 'tv';
            return Movie.fromJson(json);
          }));
        }
        
        // Sort by similarity to query (fuzzy search)
        allResults.sort((a, b) {
          double similarityA = _calculateSimilarity(query, a.title);
          double similarityB = _calculateSimilarity(query, b.title);
          return similarityB.compareTo(similarityA); // Higher similarity first
        });
        
        String filterInfo = '';
        if (year != null) filterInfo += ' [Year: $year]';
        if (language != null) filterInfo += ' [Language: $language]';
        print('Found ${allResults.length} results (movies + TV shows) for "$query"$filterInfo, sorted by relevance');
        return allResults;
      } catch (e) {
        if (attempt < 2) await Future.delayed(Duration(milliseconds: 500));
        else print('Error searching all content: $e');
      }
    }
    return [];
  }

  // Get content in specific language
  Future<List<Movie>> getPopularByLanguage(String languageCode, {int page = 1}) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        // Create TMDB instance with specific language
        final tmdbLang = TMDB(
          ApiKeys(apiKey, accessToken),
          defaultLanguage: languageCode,
        );
        
        final movieResult = await tmdbLang.v3.movies.getPopular(page: page);
        final tvResult = await tmdbLang.v3.tv.getPopular(page: page);

        List<Movie> allResults = [];
        
        if (movieResult['results'] != null) {
          final List<dynamic> movies = movieResult['results'];
          allResults.addAll(movies.map((json) {
            json['media_type'] = 'movie';
            return Movie.fromJson(json);
          }));
        }
        
        if (tvResult['results'] != null) {
          final List<dynamic> tvShows = tvResult['results'];
          allResults.addAll(tvShows.map((json) {
            json['media_type'] = 'tv';
            return Movie.fromJson(json);
          }));
        }
        
        return allResults;
      } catch (e) {
        if (attempt < 2) await Future.delayed(Duration(milliseconds: 1000));
      }
    }
    return [];
  }
}

