import 'package:flutter/material.dart';
import 'package:movielistsuggest/models/movie.dart';
import 'package:movielistsuggest/services/movie_list_service.dart';
import 'package:movielistsuggest/widgets/star_rating.dart';
import 'package:movielistsuggest/services/auth_service.dart';

class MovieDetailsPage extends StatefulWidget {
  final Movie movie;

  const MovieDetailsPage({Key? key, required this.movie}) : super(key: key);

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  final MovieListService _listService = MovieListService();
  final AuthService _authService = AuthService();

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          // User profile icon
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _authService.currentUser?.photoURL != null 
                    ? Icons.account_circle 
                    : Icons.person,
                color: Colors.black87,
              ),
              onPressed: () {
                // Could show user profile or settings
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full-screen backdrop image with gradient
          Positioned.fill(
            child: Stack(
              children: [
                // Backdrop image
                widget.movie.backdropUrl.isNotEmpty
                    ? Image.network(
                        widget.movie.backdropUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) => 
                          widget.movie.posterUrl.isNotEmpty
                              ? Image.network(
                                  widget.movie.posterUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  alignment: Alignment.topCenter,
                                )
                              : Container(color: Colors.grey[900]),
                      )
                    : (widget.movie.posterUrl.isNotEmpty
                        ? Image.network(
                            widget.movie.posterUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            alignment: Alignment.topCenter,
                          )
                        : Container(color: Colors.grey[900])),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.95),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top spacing for image
                        SizedBox(height: MediaQuery.of(context).size.height * 0.35),

                        // Rating badge positioned top-right
                        Align(
                          alignment: Alignment.topRight,
                          child: InkWell(
                            onTap: _showAddToListDialog,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              margin: const EdgeInsets.only(right: 16, bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.playlist_add,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Rating badge positioned top-right
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            margin: const EdgeInsets.only(right: 16, bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  userRating != null ? '${userRating.toStringAsFixed(0)}/10' : '-/10',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (userRating != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 30,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: _getRatingColor(userRating),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        
                        // Movie title
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            widget.movie.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Metadata bar (Genre, IMDb rating, Duration)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Genre (placeholder - you can add genre to Movie model)
                              const Text(
                                'Movie',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.white70,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // IMDb rating
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5C518),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'IMDb',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.movie.voteAverage?.toStringAsFixed(1) ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.white70,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Duration/Year
                              Text(
                                widget.movie.year,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Synopsis
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            widget.movie.overview ?? 'No overview available.',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Action buttons (Booking style)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              // Like button
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isLiked ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: isLiked ? Colors.red : Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(30),
                                      onTap: () async {
                                        await _listService.toggleLike(widget.movie);
                                        setState(() {});
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              isLiked ? Icons.favorite : Icons.favorite_border,
                                              color: isLiked ? Colors.red : Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isLiked ? 'Liked' : 'Like',
                                              style: TextStyle(
                                                color: isLiked ? Colors.red : Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Watchlist button (Booking style)
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isInWatchlist 
                                          ? [Colors.green.shade600, Colors.green.shade400]
                                          : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(30),
                                      onTap: () async {
                                        if (isInWatchlist) {
                                          await _listService.removeMovieFromList('watchlist', widget.movie.id);
                                        } else {
                                          await _listService.addMovieToList('watchlist', widget.movie);
                                        }
                                        setState(() {});
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                                              color: isInWatchlist ? Colors.white : Colors.black87,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isInWatchlist ? 'In Watchlist' : 'Add to Watchlist',
                                              style: TextStyle(
                                                color: isInWatchlist ? Colors.white : Colors.black87,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward,
                                              color: isInWatchlist ? Colors.white : Colors.black87,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // User rating section
                        if (showRating) ...[
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Rating',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
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
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Add to list button
                        // ...existing code...
                        // Add to list button
                    
                        
                        const SizedBox(height: 52),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating <= 3) return Colors.red;
    if (rating <= 5) return Colors.orange;
    if (rating <= 7) return Colors.amber;
    if (rating <= 9) return Colors.lightGreen;
    return Colors.green;
  }
}
