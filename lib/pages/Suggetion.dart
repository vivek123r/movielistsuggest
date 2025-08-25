import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:movielistsuggest/models/movie.dart';
import 'package:movielistsuggest/pages/MovieDetailspage.dart';
import 'package:movielistsuggest/services/movie_api_service.dart';
import 'package:movielistsuggest/services/watch_list_service.dart';

class SuggestionPage extends StatefulWidget {
  const SuggestionPage({super.key});

  @override
  State<SuggestionPage> createState() => _SuggestionPageState();
}

class _SuggestionPageState extends State<SuggestionPage> {
  final TextEditingController _promptController = TextEditingController();
  final WatchListService _watchListService = WatchListService();
  final MovieApiService _movieApiService = MovieApiService();

  List<Movie> _suggestedMovies = [];
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    // Initialize with watch list if available
    _checkWatchList();
  }

  Future<void> _checkWatchList() async {
    await _watchListService.loadWatchList();
    if (_watchListService.watchList.isNotEmpty &&
        _promptController.text.isEmpty) {
      _promptController.text =
          "Suggest movies similar to: ${_watchListService.watchList.take(3).map((m) => m.title).join(', ')}";
    }
  }

  Future<void> _getMovieSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final prompt = _promptController.text;

      if (prompt.isEmpty) {
        setState(() {
          _error = 'Please enter a prompt for movie suggestions';
          _isLoading = false;
        });
        return;
      }

      // Get suggestions from AI
      final List<String> movieTitles = await _getGeminiSuggestions(prompt);

      // Search for each movie using TMDb API
      _suggestedMovies = [];
      for (final title in movieTitles) {
        final results = await _movieApiService.searchMovies(title);
        if (results.isNotEmpty) {
          _suggestedMovies.add(results.first);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error getting suggestions: $e';
        _isLoading = false;
      });
    }
  }

  // Use Google's Gemini AI API to get movie suggestions
  // Update the _getGeminiSuggestions method to handle null values and different JSON structures

  Future<List<String>> _getGeminiSuggestions(String prompt) async {
    // First, change the model name to gemini-pro instead of gemini-2.5-pro
    const apiKey = 'AIzaSyCiMqyy2HVu2Pa7Rlzqss6qGfbfBllJzyI';
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=$apiKey',
    );

    try {
      final fullPrompt =
          'Suggest 5 movies based on this request: "$prompt". '
          'Return only the movie titles as a numbered list. '
          'Be concise and only list the titles without additional text.';

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': fullPrompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Add proper null checks to prevent the "method called on null" error
        if (data == null ||
            data['candidates'] == null ||
            data['candidates'].isEmpty ||
            data['candidates'][0]['content'] == null ||
            data['candidates'][0]['content']['parts'] == null ||
            data['candidates'][0]['content']['parts'].isEmpty) {
          print('Invalid response structure: ${response.body}');
          return _getFallbackMovieSuggestions(prompt);
        }

        final text = data['candidates'][0]['content']['parts'][0]['text'];
        if (text == null) {
          print('No text in response: ${response.body}');
          return _getFallbackMovieSuggestions(prompt);
        }

        // Extract movie titles from the response
        List<String> titles = [];
        final lines = text.split('\n');

        for (var line in lines) {
          // Remove numbering and extra characters
          line = line.trim();
          if (line.isEmpty) continue;

          // Parse out the numbered list format: "1. Movie Title" or "1) Movie Title"
          final regExp = RegExp(r'^\d+[\.\)\:]?\s*(.+)$');
          final match = regExp.firstMatch(line);

          if (match != null && match.groupCount >= 1) {
            titles.add(match.group(1)!.trim());
          } else if (!line.startsWith('Here') &&
              !line.contains('movies') &&
              !line.contains('suggestions')) {
            // Fallback if the format isn't as expected but isn't header text
            titles.add(line);
          }
        }

        if (titles.isEmpty) {
          print('No titles extracted from: $text');
          return _getFallbackMovieSuggestions(prompt);
        }

        return titles.take(5).toList();
      } else {
        print('Error response: ${response.statusCode} ${response.body}');
        return _getFallbackMovieSuggestions(prompt);
      }
    } catch (e) {
      print('Error in AI suggestions: $e');
      return _getFallbackMovieSuggestions(prompt);
    }
  }

  // Add a fallback method that returns popular movie suggestions
  List<String> _getFallbackMovieSuggestions(String prompt) {
    // Return different suggestions based on keywords in the prompt
    final lowerPrompt = prompt.toLowerCase();

    if (lowerPrompt.contains('action') || lowerPrompt.contains('thriller')) {
      return [
        'Die Hard',
        'Mad Max: Fury Road',
        'The Dark Knight',
        'John Wick',
        'Mission: Impossible - Fallout',
      ];
    } else if (lowerPrompt.contains('comedy') ||
        lowerPrompt.contains('funny')) {
      return [
        'Superbad',
        'The Hangover',
        'Bridesmaids',
        'Dumb and Dumber',
        'Step Brothers',
      ];
    } else if (lowerPrompt.contains('horror') ||
        lowerPrompt.contains('scary')) {
      return [
        'The Shining',
        'Hereditary',
        'Get Out',
        'A Quiet Place',
        'The Conjuring',
      ];
    } else if (lowerPrompt.contains('sci') || lowerPrompt.contains('fiction')) {
      return [
        'Inception',
        'The Matrix',
        'Interstellar',
        'Blade Runner 2049',
        'Dune',
      ];
    } else {
      // Default popular movies
      return [
        'The Shawshank Redemption',
        'The Godfather',
        'Pulp Fiction',
        'The Dark Knight',
        'Fight Club',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'AI Movie Recommendations',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tell us what you want to watch:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            decoration: InputDecoration(
              hintText:
                  'E.g., "Action movies like Die Hard" or "Feel-good comedies"',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _promptController.clear(),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _getMovieSuggestions,
            child:
                _isLoading
                    ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Getting recommendations...'),
                      ],
                    )
                    : const Text('Get Recommendations'),
          ),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(_error, style: TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 16),
          _isLoading
              ? const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(),
                      ),
                      SizedBox(height: 16),
                      Text('Finding perfect movies for you...'),
                    ],
                  ),
                ),
              )
              : _suggestedMovies.isEmpty
              ? const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.movie_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Enter a prompt to get personalized movie recommendations',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
              : Expanded(
                child: ListView.builder(
                  itemCount: _suggestedMovies.length,
                  itemBuilder: (context, index) {
                    final movie = _suggestedMovies[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => MovieDetailsPage(movie: movie),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Movie poster
                              movie.posterUrl.isNotEmpty
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      movie.posterUrl,
                                      width: 100,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          width: 100,
                                          height: 150,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.movie,
                                            size: 40,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                  : Container(
                                    width: 100,
                                    height: 150,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.movie, size: 40),
                                  ),
                              const SizedBox(width: 16),
                              // Movie details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      movie.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          movie.year,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (movie.voteAverage != null) ...[
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            movie.voteAverage!.toStringAsFixed(
                                              1,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      movie.overview ?? 'No overview available',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.info_outline),
                                          label: const Text('Details'),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        MovieDetailsPage(
                                                          movie: movie,
                                                        ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          icon: Icon(
                                            _watchListService.isInWatchList(
                                                  movie.id,
                                                )
                                                ? Icons.check
                                                : Icons.add,
                                          ),
                                          label: Text(
                                            _watchListService.isInWatchList(
                                                  movie.id,
                                                )
                                                ? 'In Watchlist'
                                                : 'Add to Watchlist',
                                          ),
                                          onPressed: () {
                                            _watchListService.toggleMovie(
                                              movie,
                                            );
                                            setState(() {});
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                _watchListService.isInWatchList(
                                                      movie.id,
                                                    )
                                                    ? Colors.green
                                                    : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }
}
