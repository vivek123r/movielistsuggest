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

    try {
      // Use the tmdb_api package to search movies
      final result = await tmdb.v3.search.queryMovies(query);

      // Check if results exist
      if (result['results'] != null) {
        final List<dynamic> movieResults = result['results'];
        return movieResults.map((json) => Movie.fromJson(json)).toList();
      } else {
        print('No results found');
        return [];
      }
    } catch (e) {
      print('TMDB API error: $e');
      return [];
    }
  }
}
