class FilmInfo {
  final int filmId;
  final String originalName;
  final String description;
  final int releaseYear;
  final String duration;
  final String maturityRating;
  final int countryId;
  final String countryName;
  final int processEpisode;
  final int totalEpisode;
  final String trailerUrl;
  final String filmStatus;

  // 🔹 Hai loại ảnh khác nhau
  final String posterMain;   // Ảnh chính (Postertype_id = 1)
  final String posterBanner; // Ảnh ngang cho banner (Postertype_id = 3)

  FilmInfo({
    required this.filmId,
    required this.originalName,
    required this.description,
    required this.releaseYear,
    required this.duration,
    required this.maturityRating,
    required this.countryId,
    required this.countryName,
    required this.processEpisode,
    required this.totalEpisode,
    required this.trailerUrl,
    required this.filmStatus,
    required this.posterMain,
    required this.posterBanner,
  });

  factory FilmInfo.fromJson(Map<String, dynamic> json) {
    return FilmInfo(
      filmId: json['Film_id'] is int
          ? json['Film_id']
          : int.tryParse(json['Film_id'].toString()) ?? 0,
      originalName: json['Original_name'] ?? '',
      description: json['Description'] ?? '',
      releaseYear: json['Release_year'] is int
          ? json['Release_year']
          : int.tryParse(json['Release_year'].toString()) ?? 0,
      duration: json['Duration'] ?? '',
      maturityRating: json['maturity_rating'] ?? '',
      countryId: json['Country_id'] is int
          ? json['Country_id']
          : int.tryParse(json['Country_id'].toString()) ?? 0,
      countryName: json['Country_name'] ?? '',
      processEpisode: json['process_episode'] is int
          ? json['process_episode']
          : int.tryParse(json['process_episode'].toString()) ?? 0,
      totalEpisode: json['total_episode'] is int
          ? json['total_episode']
          : int.tryParse(json['total_episode'].toString()) ?? 0,
      trailerUrl: json['trailer_url'] ?? '',
      filmStatus: json['film_status'] ?? '',
      posterMain: json['poster_main'] ?? '',     // ✅ Ảnh chính
      posterBanner: json['poster_banner'] ?? '', // ✅ Ảnh banner
    );
  }

  Map<String, dynamic> toJson() => {
    'Film_id': filmId,
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
    'poster_main': posterMain,
    'poster_banner': posterBanner,
  };
}
