class Movie {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double? voteAverage;
  final String? overview;
  final String mediaType; // 'movie' or 'tv'
  final String? originalLanguage;

  Movie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage,
    this.overview,
    this.mediaType = 'movie',
    this.originalLanguage,
  });

  String get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';

  String get backdropUrl =>
      backdropPath != null
          ? 'https://image.tmdb.org/t/p/w1280$backdropPath'
          : '';

  String get year =>
      releaseDate != null && releaseDate!.length >= 4
          ? releaseDate!.substring(0, 4)
          : '';

  String get displayTitle => mediaType == 'tv' ? '$title (TV)' : title;

  factory Movie.fromJson(Map<String, dynamic> json) {
    // Determine media type
    String type = json['media_type'] ?? 'movie';
    
    // For TV shows, use 'name' instead of 'title' and 'first_air_date' instead of 'release_date'
    String title = json['title'] ?? json['name'] ?? 'Unknown';
    String? releaseDate = json['release_date'] ?? json['first_air_date'];
    
    return Movie(
      id: json['id'] ?? 0,
      title: title,
      posterPath: json['posterPath'] ?? json['poster_path'],
      backdropPath: json['backdropPath'] ?? json['backdrop_path'],
      releaseDate: releaseDate,
      voteAverage: (json['voteAverage'] ?? json['vote_average'])?.toDouble(),
      overview: json['overview'],
      mediaType: json['mediaType'] ?? type,
      originalLanguage: json['originalLanguage'] ?? json['original_language'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'releaseDate': releaseDate,
      'voteAverage': voteAverage,
      'overview': overview,
      'mediaType': mediaType,
      'originalLanguage': originalLanguage,
    };
  }
}
