import 'package:flutter/material.dart';
import 'package:movielistsuggest/models/movie.dart';
import 'package:movielistsuggest/pages/MovieDetailspage.dart';
import 'package:movielistsuggest/services/watch_list_service.dart';

class WatchListPage extends StatefulWidget {
  const WatchListPage({super.key});

  @override
  State<WatchListPage> createState() => _WatchListPageState();
}

class _WatchListPageState extends State<WatchListPage> {
  final WatchListService _watchListService = WatchListService();
  List<Movie> _watchList = [];
  bool _isLoading = true;
  SortCriteria _currentSort = SortCriteria.titleAsc;

  // Stats
  int _totalMovies = 0;
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _watchListService.watchListNotifier.addListener(_refreshList);
    _loadWatchList();
  }

  @override
  void dispose() {
    _watchListService.watchListNotifier.removeListener(_refreshList);
    super.dispose();
  }

  void _refreshList() {
    if (mounted) {
      setState(() {
        _watchList = _watchListService.watchList;
        _updateStats();
      });
    }
  }

  Future<void> _loadWatchList() async {
    setState(() {
      _isLoading = true;
    });

    await _watchListService.loadWatchList();

    setState(() {
      _watchList = _watchListService.watchList;
      _isLoading = false;
      _updateStats();
    });
  }

  void _updateStats() {
    final stats = _watchListService.getStats();
    _totalMovies = stats['totalMovies'];
    _averageRating = stats['averageRating'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          // Header with title and actions
          _buildHeader(context),

          // Stats display
          if (_watchList.isNotEmpty) _buildStatsCard(),

          // Movie list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _watchList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                      onRefresh: _loadWatchList,
                      child: ListView.builder(
                        itemCount: _watchList.length,
                        itemBuilder: (context, index) {
                          final movie = _watchList[index];
                          return _buildMovieCard(movie);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Text(
            "My Watch List",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // Sort button
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onPressed: _showSortOptions,
          ),
          // Clear list button
          if (_watchList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all',
              onPressed: _confirmClearList,
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.movie_outlined,
              label: 'Movies',
              value: _totalMovies.toString(),
            ),
            _buildStatItem(
              icon: Icons.star,
              label: 'Avg Rating',
              value:
                  _averageRating > 0 ? _averageRating.toStringAsFixed(1) : '-',
              color: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_filter, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Your watch list is empty",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add movies from the search page",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCard(Movie movie) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailsPage(movie: movie),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Movie poster
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child:
                    movie.posterUrl.isNotEmpty
                        ? Image.network(
                          movie.posterUrl,
                          width: 70,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 70,
                              height: 100,
                              color: Colors.grey[300],
                              child: const Icon(Icons.movie, size: 40),
                            );
                          },
                        )
                        : Container(
                          width: 70,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.movie, size: 40),
                        ),
              ),

              // Movie info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (movie.year.isNotEmpty)
                        Text(
                          movie.year,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      if (movie.voteAverage != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              movie.voteAverage!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDeleteMovie(movie),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: const Text('Sort by'), enabled: false),
              const Divider(),
              ...SortCriteria.values.map(
                (criteria) => ListTile(
                  leading:
                      _currentSort == criteria
                          ? const Icon(Icons.check, color: Colors.blue)
                          : const SizedBox(width: 24),
                  title: Text(criteria.name),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentSort = criteria;
                      _watchListService.sortWatchList(criteria);
                    });
                  },
                ),
              ),
            ],
          ),
    );
  }

  void _confirmClearList() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear watch list?'),
            content: const Text(
              'This will remove all movies from your watch list. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _watchListService.clearWatchList();
                },
                child: const Text('CLEAR'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
    );
  }

  void _confirmDeleteMovie(Movie movie) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Remove ${movie.title}?'),
            content: const Text('Remove this movie from your watch list?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _watchListService.removeMovie(movie.id);
                },
                child: const Text('REMOVE'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
    );
  }
}
