import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:movielistsuggest/models/movie.dart';
import 'package:movielistsuggest/pages/MovieDetailspage.dart';
import 'package:movielistsuggest/services/movie_api_service.dart';
import 'package:movielistsuggest/services/watch_list_service.dart';
// import 'package:video_player/video_player.dart';
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
  // VideoPlayerController? _videoController;
  // bool _videoInitialized = false;

  List<Movie> _suggestedMovies = [];
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    // Initialize with watch list if available
    _checkWatchList();
    // initialize video controller for local asset video (if provided)
    // Note: add your video file at assets/aibotvideo.mp4 and enable in pubspec.yaml
    // _initializeVideo();
  }

  // Future<void> _initializeVideo() async {
  //   try {
  //     _videoController = VideoPlayerController.asset(
  //       'assets/aibotvideo2.mp4',
  //       videoPlayerOptions: VideoPlayerOptions(
  //         mixWithOthers: true,
  //         allowBackgroundPlayback: false,
  //       ),
  //     );
  //     await _videoController!.initialize();
  //     _videoController!.setLooping(true);
  //     _videoController!.setVolume(0.0); // Mute the video to reduce processing
  //     _videoController!.play();
  //     setState(() {
  //       _videoInitialized = true;
  //     });
  //   } catch (e) {
  //     // Video asset doesn't exist or failed to load - fall back to image
  //     print('Video not available (will show image instead): $e');
  //     setState(() {
  //       _videoInitialized = false;
  //       _videoController = null;
  //     });
  //   }
  // }

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
    const apiKey = 'AIzaSyDIkzcNqeOPeANHqzpYtCjHZXfP-jAuhB8';
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}',
    );

    try {
      // Simple prompt - just ask for 10 movie titlesS
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': '''User request: "$prompt"

If the user is asking for movies in a specific franchise/series (e.g., "all fast and furious", "harry potter movies", "marvel movies"), list the actual movies from that franchise.
If the user is asking for recommendations (e.g., "sad movies", "action movies", "movies like inception"), suggest 10 similar real movies.

Return ONLY movie titles, one per line. No explanations, no numbering, no additional text.'''},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 250,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Full API Response: ${response.body}');

        // Extract text from response
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        
        if (text == null || text.isEmpty) {
          print('No text in AI response, using fallback');
          return _getFallbackMovieSuggestions(prompt);
        }

        print('AI response: $text');

        // Extract movie titles - split by newlines and clean up
        final lines = text.split('\n');
        final List<String> titles = [];
        
        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty) continue;
          
          // Remove numbering, bullets, asterisks
          line = line.replaceAll(RegExp(r'^\d+[\.\)\:\-]\s*'), '');
          line = line.replaceAll(RegExp(r'^\*+\s*'), '');
          line = line.replaceAll(RegExp(r'^[\-\•]\s*'), '');
          line = line.trim();
          
          // Filter out invalid lines
          if (line.isNotEmpty && 
              line.length > 1 &&
              !line.toLowerCase().startsWith('here') &&
              !line.toLowerCase().startsWith('based on')) {
            titles.add(line);
            if (titles.length >= 10) break;
          }
        }

        print('Extracted ${titles.length} movie titles: $titles');

        if (titles.isEmpty) {
          print('No valid titles extracted, using fallback');
          return _getFallbackMovieSuggestions(prompt);
        }

        return titles;
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        return _getFallbackMovieSuggestions(prompt);
      }
    } catch (e) {
      print('Exception in AI suggestions: $e');
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.purple.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AI Recommendations',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Full width video/image - no padding, no gaps
          // if (_videoInitialized && _videoController != null)
          //   SizedBox(
          //     width: double.infinity,
          //     child: AspectRatio(
          //       aspectRatio: _videoController!.value.aspectRatio,
          //       child: VideoPlayer(_videoController!),
          //     ),
          //   )
          // else
            // Fallback image
            SizedBox(
              width: double.infinity,
              child: Image.asset(
                'assets/aibot2.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    child: const Icon(Icons.smart_toy, size: 80, color: Colors.blue),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _promptController,
                  decoration: InputDecoration(
                    hintText: 'E.g., "Action movies like Die Hard" or "Feel-good comedies"',
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
              ? const SizedBox(
                height: 300,
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
              ? const SizedBox(
                height: 300,
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
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                                        Flexible(
                                          child: ElevatedButton.icon(
                                          icon: Icon(
                                            _watchListService.isInWatchList(
                                                  movie.id,
                                                )
                                                ? Icons.check
                                                : Icons.add,
                                              size: 16
                                          ),
                                          label: Text(
                                            _watchListService.isInWatchList(
                                                  movie.id,
                                                )
                                                ? 'Added'
                                                : 'Add',
                                              overflow: TextOverflow.ellipsis,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // _videoController?.dispose();
    _promptController.dispose();
    super.dispose();
  }
}
