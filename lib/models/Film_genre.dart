class FilmGenre {
  final int filmId;
  final int genreId;

  FilmGenre({
    required this.filmId,
    required this.genreId,
  });

  factory FilmGenre.fromJson(Map<String, dynamic> json) {
    return FilmGenre(
      filmId: json['Film_id'] is int
          ? json['Film_id']
          : int.tryParse(json['Film_id'].toString()) ?? 0,
      genreId: json['Genre_id'] is int
          ? json['Genre_id']
          : int.tryParse(json['Genre_id'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'Film_id': filmId,
    'Genre_id': genreId,
  };
}
