class Genre {
  final int genreId;
  final String genreName;

  Genre({
    required this.genreId,
    required this.genreName,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      genreId: json['Genre_id'] is int
          ? json['Genre_id']
          : int.tryParse(json['Genre_id'].toString()) ?? 0,
      genreName: json['Genre_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'Genre_id': genreId,
    'Genre_name': genreName,
  };
}
