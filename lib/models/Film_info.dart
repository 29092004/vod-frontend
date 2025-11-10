class FilmInfo {
  final int filmId;
  final String filmName;
  final String originalName;
  final String description;
  final int releaseYear;
  final String duration;
  final String maturityRating;
  final int? countryId;
  final String countryName;
  final int processEpisode;
  final int totalEpisode;
  final String trailerUrl;
  final String filmStatus;
  final bool isSeries;
  final String genres;
  final String posterMain;
  final String posterBanner;
  final List<dynamic> actors; // ✅ danh sách diễn viên
  final String? sources;
  final List<dynamic>? seasons; // ✅ thêm danh sách mùa (Season + Episode)

  FilmInfo({
    required this.filmId,
    required this.filmName,
    required this.originalName,
    required this.description,
    required this.releaseYear,
    required this.duration,
    required this.maturityRating,
    this.countryId,
    required this.countryName,
    required this.processEpisode,
    required this.totalEpisode,
    required this.trailerUrl,
    required this.filmStatus,
    required this.isSeries,
    required this.genres,
    required this.posterMain,
    required this.posterBanner,
    required this.actors,
    this.sources,
    this.seasons, // ✅ thêm vào constructor
  });

  factory FilmInfo.fromJson(Map<String, dynamic> json) {
    return FilmInfo(
      filmId: json['Film_id'] ?? 0,
      filmName: json['Film_name'] ?? '',
      originalName: json['Original_name'] ?? '',
      description: json['Description'] ?? '',
      releaseYear: json['Release_year'] ?? 0,
      duration: json['Duration'] ?? '',
      maturityRating: json['maturity_rating'] ?? '',
      countryId: json['Country_id'],
      countryName: json['Country_name'] ?? '',
      processEpisode: json['process_episode'] ?? 0,
      totalEpisode: json['total_episode'] ?? 0,
      trailerUrl: json['trailer_url'] ?? '',
      filmStatus: json['film_status'] ?? '',
      isSeries: json['is_series'] == 1 || json['is_series'] == true,
      genres: json['genres'] ?? '',
      posterMain: json['poster_main'] ?? '',
      posterBanner: json['poster_banner'] ?? '',
      actors: (json['Actors'] is List) ? json['Actors'] : [],
      sources: json['Sources'],
      seasons: (json['Seasons'] is List) ? json['Seasons'] : [], // ✅ thêm parse
    );
  }

  Map<String, dynamic> toJson() => {
    'Film_id': filmId,
    'Film_name': filmName,
    'Original_name': originalName,
    'Description': description,
    'Release_year': releaseYear,
    'Duration': duration,
    'maturity_rating': maturityRating,
    'Country_id': countryId,
    'Country_name': countryName,
    'process_episode': processEpisode,
    'total_episode': totalEpisode,
    'trailer_url': trailerUrl,
    'film_status': filmStatus,
    'is_series': isSeries,
    'genres': genres,
    'poster_main': posterMain,
    'poster_banner': posterBanner,
    'Actors': actors,
    'Sources': sources,
    'Seasons': seasons, // ✅ xuất ra JSON luôn
  };
}
