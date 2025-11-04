class FilmSource {
  final int filmId;
  final int episodeId;
  final int resolutionId;
  final String sourceUrl;

  FilmSource({
    required this.filmId,
    required this.episodeId,
    required this.resolutionId,
    required this.sourceUrl,
  });

  factory FilmSource.fromJson(Map<String, dynamic> json) {
    return FilmSource(
      filmId: json['Film_id'] is int
          ? json['Film_id']
          : int.tryParse(json['Film_id'].toString()) ?? 0,
      episodeId: json['Episode_id'] is int
          ? json['Episode_id']
          : int.tryParse(json['Episode_id'].toString()) ?? 0,
      resolutionId: json['Resolution_id'] is int
          ? json['Resolution_id']
          : int.tryParse(json['Resolution_id'].toString()) ?? 0,
      sourceUrl: json['Source_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'Film_id': filmId,
    'Episode_id': episodeId,
    'Resolution_id': resolutionId,
    'Source_url': sourceUrl,
  };
}
