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

  Future<List<Movie>> searchMovies(String query) async {
    if (query.isEmpty) return [];
    for (int attempt =0 ; attempt < 3; attempt++) {
    try {
      // Use the tmdb_api package to search movies
      final result = await tmdb.v3.search.queryMovies(query);

      // Check if results exist
      if (result['results'] != null) {
        final List<dynamic> movieResults = result['results'];
        return movieResults.map((json) => Movie.fromJson(json)).toList();
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
  Future<List<Movie>> getUpcomingMovies({int page = 1}) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        print('Fetching upcoming movies, attempt ${attempt + 1}');
        
        final result = await tmdb.v3.movies.getUpcoming(page: page);

        if (result['results'] != null) {
          final List<dynamic> movieResults = result['results'];
          print('Found ${movieResults.length} upcoming movies');
          return movieResults.map((json) => Movie.fromJson(json)).toList();
        } else {
          print('No upcoming movies found');
        }
      } catch (e) {
        print('Error fetching upcoming movies on attempt ${attempt + 1}: $e');
        if (attempt < 2) {
          await Future.delayed(Duration(milliseconds: 1000));
        } else {
          print('All attempts failed for upcoming movies');
          return [];
        }
      }
    }
    return [];
  }
}
