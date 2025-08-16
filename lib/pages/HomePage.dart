import 'package:flutter/material.dart';
import 'package:movielistsuggest/models/movie.dart';
import 'package:movielistsuggest/pages/MovieDetailspage.dart';
import 'package:movielistsuggest/services/movie_api_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final MovieApiService apiService = MovieApiService();
  List<Movie> _searchResults = [];
  bool isLoading = false;

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
                        ? Center(child: Text("Search for movies"))
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
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MovieDetailsPage(),
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
