import 'package:flutter/material.dart';
import 'package:movielistsuggest/models/movie.dart';
import 'package:movielistsuggest/pages/MovieDetailspage.dart';
import 'package:movielistsuggest/services/movie_list_service.dart';

enum SortCriteria {
  titleAsc,
  titleDesc,
  ratingAsc,
  ratingDesc,
  dateAddedAsc,
  dateAddedDesc,
}

class WatchListPage extends StatefulWidget {
  const WatchListPage({super.key});

  @override
  State<WatchListPage> createState() => _WatchListPageState();
}

class _WatchListPageState extends State<WatchListPage> {
  final MovieListService _listService = MovieListService();
  List<Movie> _watchList = [];
  bool _isLoading = true;
  SortCriteria _currentSort = SortCriteria.titleAsc;
  String _selectedListId = 'watchlist'; // Default to watch list
  
  // Stats
  int _totalMovies = 0;
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _listService.addListener(_refreshList);
    _ensureInitialized();
  }

  Future<void> _ensureInitialized() async {
    // Wait for service to be initialized
    if (!_listService.isInitialized) {
      await _listService.initialize();
    }
    _loadList();
  }

  @override
  void dispose() {
    _listService.removeListener(_refreshList);
    super.dispose();
  }

  void _refreshList() {
    if (mounted) {
      _loadList();
    }
  }

  Future<void> _loadList() async {
    setState(() {
      _isLoading = true;
    });

    final list = _listService.getList(_selectedListId);
    
    setState(() {
      _watchList = list?.movies ?? [];
      _isLoading = false;
      _updateStats();
    });
  }

  void _updateStats() {
    final stats = _listService.getListStats(_selectedListId);
    _totalMovies = stats['totalMovies'];
    _averageRating = stats['averageRating'];
  }

  void _sortList(SortCriteria criteria) {
    setState(() {
      _currentSort = criteria;
      switch (criteria) {
        case SortCriteria.titleAsc:
          _watchList.sort((a, b) => a.title.compareTo(b.title));
          break;
        case SortCriteria.titleDesc:
          _watchList.sort((a, b) => b.title.compareTo(a.title));
          break;
        case SortCriteria.ratingAsc:
          _watchList.sort((a, b) => (a.voteAverage ?? 0).compareTo(b.voteAverage ?? 0));
          break;
        case SortCriteria.ratingDesc:
          _watchList.sort((a, b) => (b.voteAverage ?? 0).compareTo(a.voteAverage ?? 0));
          break;
        case SortCriteria.dateAddedAsc:
        case SortCriteria.dateAddedDesc:
          // For now, keep original order
          break;
      }
    });
  }

  void createList() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Movie List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'List Name',
                hintText: 'e.g., Action Movies, Favorites',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              String listName = nameController.text.trim();
              if (listName.isNotEmpty) {
                final newListId = await _listService.createList(listName);
                setState(() {
                  _selectedListId = newListId;
                });
                await _loadList();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('List "$listName" created!')),
                );
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  void _showListSelector() {
    final allLists = _listService.allLists;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          ...allLists.map(
            (list) => ListTile(
              leading: Icon(
                _selectedListId == list.id
                    ? Icons.check_circle
                    : (list.id == 'liked'
                        ? Icons.favorite
                        : list.id == 'watchlist'
                            ? Icons.bookmark
                            : Icons.list),
                color: _selectedListId == list.id
                    ? Colors.blue
                    : (list.id == 'liked' ? Colors.red : Colors.grey),
              ),
              title: Text(list.name),
              subtitle: Text('${list.movies.length} movies'),
              trailing: !list.isDefault
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDeleteList(list.id, list.name);
                      },
                    )
                  : null,
              onTap: () {
                setState(() {
                  _selectedListId = list.id;
                });
                _loadList();
                Navigator.pop(context);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
            title: const Text('Create New List'),
            onTap: () {
              Navigator.pop(context);
              createList();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _confirmDeleteList(String listId, String listName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "$listName"?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await _listService.deleteList(listId);
              if (_selectedListId == listId) {
                setState(() {
                  _selectedListId = 'watchlist';
                });
                await _loadList();
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('List "$listName" deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
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

          // createList
          Center(
            child: ElevatedButton(
              onPressed: () {
                createList();
              },
              child: const Text('Create Movie List'),
            ),
          ),

          // Movie list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _watchList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                      onRefresh: _loadList,
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
    final currentList = _listService.getList(_selectedListId);
    final listName = currentList?.name ?? 'Watch List';
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // List selector
          InkWell(
            onTap: _showListSelector,
            child: Row(
              children: [
                Icon(
                  _selectedListId == 'liked'
                      ? Icons.favorite
                      : _selectedListId == 'watchlist'
                          ? Icons.bookmark
                          : Icons.list,
                  color: _selectedListId == 'liked' ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  listName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.arrow_drop_down, size: 24),
              ],
            ),
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
                    _sortList(criteria);
                  },
                ),
              ),
            ],
          ),
    );
  }

  void _confirmClearList() {
    final currentList = _listService.getList(_selectedListId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear ${currentList?.name ?? "list"}?'),
        content: const Text(
          'This will remove all movies from this list. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _listService.clearList(_selectedListId);
              await _loadList();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMovie(Movie movie) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${movie.title}?'),
        content: const Text('Remove this movie from this list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _listService.removeMovieFromList(_selectedListId, movie.id);
              await _loadList();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
  }
}
