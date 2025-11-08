import 'package:flutter/material.dart';
import 'package:movielistsuggest/models/movie.dart';
import 'package:movielistsuggest/pages/MovieDetailspage.dart';
import 'package:movielistsuggest/services/movie_list_service.dart';
import 'package:movielistsuggest/widgets/star_rating.dart';

enum SortCriteria {
  titleAsc,
  titleDesc,
  ratingAsc,
  ratingDesc,
  dateAddedAsc,
  dateAddedDesc,
}

enum ComparisonOperator {
  greaterThan,
  lessThan,
  equalTo,
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
  
  // Rating filter state
  double _filterRatingValue = 8.0;
  ComparisonOperator _comparisonOperator = ComparisonOperator.greaterThan;
  bool _isFilterActive = false;
  
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
      _applyRatingFilter();
      _isLoading = false;
      _updateStats();
    });
  }

  void _applyRatingFilter() {
    if (_selectedListId == 'watchlist' || !_isFilterActive) {
      // No rating filter for watchlist or when filter is off
      return;
    }

    _watchList = _watchList.where((movie) {
      final rating = _listService.getMovieRating(movie.id);
      if (rating == null) return false;

      switch (_comparisonOperator) {
        case ComparisonOperator.greaterThan:
          return rating >= _filterRatingValue;
        case ComparisonOperator.lessThan:
          return rating <= _filterRatingValue;
        case ComparisonOperator.equalTo:
          return rating == _filterRatingValue;
      }
    }).toList();
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
                  _isFilterActive = false; // Reset filter when changing lists
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
          const SizedBox(height: 20),
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
          // Filter button (only for lists with ratings)
          if (_selectedListId != 'watchlist')
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: _isFilterActive ? Colors.blue : null,
              ),
              tooltip: 'Filter by rating',
              onPressed: _showRatingFilter,
            ),
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
    final userAvgRating = _selectedListId != 'watchlist' 
        ? _listService.getListAverageUserRating(_selectedListId)
        : null;
    
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
              label: 'TMDb Avg',
              value:
                  _averageRating > 0 ? _averageRating.toStringAsFixed(1) : '-',
              color: Colors.amber,
            ),
            if (userAvgRating != null)
              _buildStatItem(
                icon: Icons.grade,
                label: 'Your Avg',
                value: userAvgRating.toStringAsFixed(1),
                color: Colors.blue,
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
    final userRating = _listService.getMovieRating(movie.id);
    final showUserRating = _selectedListId != 'watchlist' && userRating != null;
    
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
                            const SizedBox(width: 4),
                            Text(
                              'TMDb',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      // User rating (only for liked/custom lists)
                      if (showUserRating) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            StarRatingDisplay(
                              rating: userRating,
                              size: 14,
                              compact: true,
                            ),
                          ],
                        ),
                      ],
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

  void _showRatingFilter() {
    String getOperatorSymbol() {
      switch (_comparisonOperator) {
        case ComparisonOperator.greaterThan:
          return '≥';
        case ComparisonOperator.lessThan:
          return '≤';
        case ComparisonOperator.equalTo:
          return '=';
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Filter by Rating'),
                const Spacer(),
                if (_isFilterActive)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isFilterActive = false;
                      });
                      Navigator.pop(context);
                      _loadList();
                    },
                    child: const Text('Clear', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select comparison operator:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // Operator buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOperatorButton(
                      '≥',
                      'Greater than or equal',
                      ComparisonOperator.greaterThan,
                      setDialogState,
                    ),
                    _buildOperatorButton(
                      '=',
                      'Equal to',
                      ComparisonOperator.equalTo,
                      setDialogState,
                    ),
                    _buildOperatorButton(
                      '≤',
                      'Less than or equal',
                      ComparisonOperator.lessThan,
                      setDialogState,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Select rating value:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Rating display
                Center(
                  child: Text(
                    _filterRatingValue.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Slider
                Slider(
                  value: _filterRatingValue,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: _filterRatingValue.toStringAsFixed(1),
                  onChanged: (value) {
                    setDialogState(() {
                      _filterRatingValue = value;
                    });
                  },
                ),
                // Number markers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(11, (index) {
                      return Text(
                        '$index',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                // Preview text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Show movies rated: ',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${getOperatorSymbol()} ${_filterRatingValue.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isFilterActive = true;
                  });
                  Navigator.pop(context);
                  _loadList();
                },
                child: const Text('APPLY FILTER'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOperatorButton(
    String symbol,
    String tooltip,
    ComparisonOperator operator,
    StateSetter setDialogState,
  ) {
    final isSelected = _comparisonOperator == operator;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () {
            setDialogState(() {
              _comparisonOperator = operator;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
            foregroundColor: isSelected ? Colors.white : Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                symbol,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                tooltip.split(' ')[0],
                style: const TextStyle(fontSize: 10),
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
