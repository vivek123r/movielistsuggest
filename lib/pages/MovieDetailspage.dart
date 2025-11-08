import 'package:flutter/material.dart';
import 'package:movielistsuggest/models/movie.dart';
import 'package:movielistsuggest/services/movie_list_service.dart';
import 'package:movielistsuggest/widgets/star_rating.dart';

class MovieDetailsPage extends StatefulWidget {
  final Movie movie;

  const MovieDetailsPage({Key? key, required this.movie}) : super(key: key);

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  final MovieListService _listService = MovieListService();

  @override
  void initState() {
    super.initState();
    _listService.addListener(_refresh);
  }

  @override
  void dispose() {
    _listService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _showAddToListDialog() {
    // Filter out the "liked" list - it should only be accessible via the like button
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final allLists = _listService.allLists.where((list) => list.id != 'liked').toList();
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Add to List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ...allLists.map(
                (list) {
                  final isInList = _listService.isInList(list.id, widget.movie.id);
                  return ListTile(
                    leading: Icon(
                      list.id == 'watchlist'
                          ? Icons.bookmark
                          : Icons.list,
                      color: isInList ? Colors.blue : Colors.grey,
                    ),
                    title: Text(list.name),
                    subtitle: Text('${list.movies.length} movies'),
                    trailing: isInList
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.add_circle_outline, color: Colors.grey),
                    onTap: () async {
                      if (isInList) {
                        await _listService.removeMovieFromList(list.id, widget.movie.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Removed from ${list.name}')),
                        );
                      } else {
                        await _listService.addMovieToList(list.id, widget.movie);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to ${list.name}')),
                        );
                      }
                      // Update both the dialog and the main page
                      setModalState(() {});
                      setState(() {});
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = _listService.isInList('liked', widget.movie.id);
    final isInWatchlist = _listService.isInList('watchlist', widget.movie.id);
    final userRating = _listService.getMovieRating(widget.movie.id);
    
    // Show rating only if movie is in liked or custom lists (not just watchlist)
    final showRating = isLiked || _listService.getListsContainingMovie(widget.movie.id)
        .any((list) => !list.isDefault);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movie.title),
        actions: [
          // Like button
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
            ),
            tooltip: isLiked ? 'Unlike' : 'Like',
            onPressed: () async {
              await _listService.toggleLike(widget.movie);
              setState(() {});
            },
          ),
          // Add to list button
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Add to list',
            onPressed: _showAddToListDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header image
            Container(
              height: 200,
              width: double.infinity,
              child:
                  widget.movie.backdropUrl.isNotEmpty
                      ? Image.network(
                        widget.movie.backdropUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.movie, size: 80),
                            ),
                      )
                      : (widget.movie.posterUrl.isNotEmpty
                          ? Image.network(
                            widget.movie.posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.movie, size: 80),
                                ),
                          )
                          : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.movie, size: 80),
                          )),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _listService.toggleLike(widget.movie);
                        setState(() {});
                      },
                      icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                      label: Text(isLiked ? 'Liked' : 'Like'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (isInWatchlist) {
                          await _listService.removeMovieFromList('watchlist', widget.movie.id);
                        } else {
                          await _listService.addMovieToList('watchlist', widget.movie);
                        }
                        setState(() {});
                      },
                      icon: Icon(isInWatchlist ? Icons.bookmark : Icons.bookmark_border),
                      label: Text(isInWatchlist ? 'In Watchlist' : 'Watchlist'),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movie.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(widget.movie.year),
                      const SizedBox(width: 16),
                      if (widget.movie.voteAverage != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(widget.movie.voteAverage!.toStringAsFixed(1)),
                            const SizedBox(width: 4),
                            Text(
                              'TMDb',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  // User rating section (only for liked or custom list movies, not watchlist only)
                  if (showRating) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Your Rating',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StarRating(
                      initialRating: userRating ?? 0.0,
                      onRatingChanged: (rating) async {
                        if (rating == 0.0) {
                          await _listService.removeMovieRating(widget.movie.id);
                        } else {
                          await _listService.setMovieRating(widget.movie.id, rating);
                        }
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userRating == null 
                          ? 'Slide to rate this movie from 1 to 10'
                          : 'Slide to change your rating',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.movie.overview ?? 'No overview available.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
