import 'package:flutter/material.dart';
import 'package:movielistsuggest/services/watchmode_service.dart';
import 'package:url_launcher/url_launcher.dart';

class StreamingPage extends StatefulWidget {
  const StreamingPage({super.key});

  @override
  State<StreamingPage> createState() => _StreamingPageState();
}

class _StreamingPageState extends State<StreamingPage> {
  final WatchmodeService _watchmodeService = WatchmodeService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedTitle;
  Map<String, dynamic> _streamingSources = {};
  bool _isLoading = false;
  bool _isLoadingSources = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchTitles(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final results = await _watchmodeService.searchTitles(query);
    
    // Sort results to prioritize movies and TV series over documentaries and TV movies
    results.sort((a, b) {
      // Priority order: movie/tv_series > tv_movie/short_film
      int getPriority(String? type) {
        if (type == 'movie' || type == 'tv_series') return 0;
        if (type == 'tv_movie') return 1;
        if (type == 'short_film') return 2;
        return 3;
      }
      
      final priorityA = getPriority(a['type']);
      final priorityB = getPriority(b['type']);
      
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }
      
      // If same priority, sort by year (newer first)
      final yearA = a['year'] ?? 0;
      final yearB = b['year'] ?? 0;
      return yearB.compareTo(yearA);
    });
    
    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  Future<void> _loadStreamingSources(int watchmodeId) async {
    setState(() {
      _isLoadingSources = true;
      _streamingSources = {};
    });

    print('🎬 Loading streaming sources for ID: $watchmodeId');
    final details = await _watchmodeService.getTitleDetails(watchmodeId);
    print('📦 Received details: ${details.keys}');
    
    setState(() {
      _streamingSources = details;
      _isLoadingSources = false;
    });
  }

  void _selectTitle(Map<String, dynamic> title) {
    print('📌 Selected title: ${title['name']} (ID: ${title['id']})');
    setState(() {
      _selectedTitle = title;
    });
    _loadStreamingSources(title['id']);
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'Search for movies or TV shows',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final title = _searchResults[index];
        final String typeLabel = title['type'] == 'tv_series' 
            ? 'TV Series' 
            : title['type'] == 'tv_movie'
            ? 'TV Movie'
            : title['type'] == 'short_film'
            ? 'Short Film'
            : 'Movie';
        
        return Card(
          color: Colors.grey[850],
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: title['image_url'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      title['image_url'],
                      width: 40,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        title['type'] == 'tv_series' ? Icons.tv : Icons.movie,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  )
                : Icon(
                    title['type'] == 'tv_series' ? Icons.tv : Icons.movie,
                    color: Colors.blue,
                    size: 40,
                  ),
            title: Text(
              title['name'] ?? 'Unknown',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  '${title['year'] ?? 'N/A'} • $typeLabel',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                if (title['tmdb_id'] != null)
                  Text(
                    'TMDb ID: ${title['tmdb_id']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
              ],
            ),
            trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            onTap: () => _selectTitle(title),
          ),
        );
      },
    );
  }

  Widget _buildStreamingSourcesList() {
    if (_isLoadingSources) {
      return Center(child: CircularProgressIndicator());
    }

    if (_selectedTitle == null) {
      return Center(
        child: Text(
          'Select a title to see streaming options',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
      );
    }

    print('📊 Streaming sources data: $_streamingSources');
    final sources = _streamingSources['sources'] as List<dynamic>?;
    print('🎯 Sources found: ${sources?.length ?? 0}');
    
    if (sources == null || sources.isEmpty) {
      // Check if we have any data at all
      final hasData = _streamingSources.isNotEmpty;
      
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey[600]),
              SizedBox(height: 16),
              Text(
                hasData ? 'No streaming sources available' : 'Unable to load streaming data',
                style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                hasData 
                  ? 'This title may not be currently available for streaming in your region'
                  : 'There was an error loading streaming information',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              if (!hasData) ...[
                SizedBox(height: 16),
                Text(
                  'Title: ${_selectedTitle!['name']}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Watchmode ID: ${_selectedTitle!['id']}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Group sources by type (subscription, free, purchase, rent)
    final Map<String, List<Map<String, dynamic>>> groupedSources = {};
    for (var source in sources) {
      final type = source['type'] ?? 'other';
      if (!groupedSources.containsKey(type)) {
        groupedSources[type] = [];
      }
      groupedSources[type]!.add(source as Map<String, dynamic>);
    }

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Title info
        Card(
          color: Colors.grey[850],
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedTitle!['name'] ?? 'Unknown',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${_selectedTitle!['year'] ?? 'N/A'} • ${_selectedTitle!['type'] == 'tv_series' ? 'TV Series' : 'Movie'}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        
        // Streaming sources by type
        ...groupedSources.entries.map((entry) {
          final typeLabel = _getTypeLabel(entry.key);
          final icon = _getTypeIcon(entry.key);
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      typeLabel,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ...entry.value.map((source) => _buildSourceCard(source)),
              SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'sub':
        return 'Subscription';
      case 'free':
        return 'Free with Ads';
      case 'buy':
        return 'Buy';
      case 'rent':
        return 'Rent';
      default:
        return 'Other';
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'sub':
        return Icons.subscriptions;
      case 'free':
        return Icons.free_breakfast;
      case 'buy':
        return Icons.shopping_cart;
      case 'rent':
        return Icons.access_time;
      default:
        return Icons.stream;
    }
  }

  Widget _buildSourceCard(Map<String, dynamic> source) {
    return Card(
      color: Colors.grey[800],
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: source['logo'] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  source['logo'],
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.play_circle_outline, size: 40),
                ),
              )
            : Icon(Icons.play_circle_outline, size: 40, color: Colors.blue),
        title: Text(
          source['name'] ?? 'Unknown Source',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: source['price'] != null
            ? Text(
                '\$${source['price']}',
                style: TextStyle(color: Colors.green),
              )
            : null,
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: () {
          if (source['web_url'] != null) {
            _launchUrl(source['web_url']);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text('Where to Watch', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(16),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search movies & TV shows...',
              leading: Icon(Icons.search, color: Colors.grey),
              backgroundColor: WidgetStateProperty.all(Colors.grey[850]),
              textStyle: WidgetStateProperty.all(
                TextStyle(color: Colors.white, fontSize: 16),
              ),
              hintStyle: WidgetStateProperty.all(
                TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              onSubmitted: _searchTitles,
            ),
          ),
          
          // Content area
          Expanded(
            child: _selectedTitle == null
                ? _buildSearchResults()
                : Row(
                    children: [
                      // Search results sidebar (on tablet/desktop)
                      if (MediaQuery.of(context).size.width > 600)
                        Container(
                          width: 300,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey[800]!),
                            ),
                          ),
                          child: _buildSearchResults(),
                        ),
                      // Streaming sources
                      Expanded(
                        child: Column(
                          children: [
                            // Back button (on mobile)
                            if (MediaQuery.of(context).size.width <= 600)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.arrow_back, color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          _selectedTitle = null;
                                        });
                                      },
                                    ),
                                    Text(
                                      'Streaming Options',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Expanded(child: _buildStreamingSourcesList()),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
