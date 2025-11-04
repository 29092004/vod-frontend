class Episode {
  final int episodeId;
  final int episodeNumber;
  final int seasonId;

  Episode({
    required this.episodeId,
    required this.episodeNumber,
    required this.seasonId,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      episodeId: json['Episode_id'] is int
          ? json['Episode_id']
          : int.tryParse(json['Episode_id'].toString()) ?? 0,
      episodeNumber: json['Episode_number'] is int
          ? json['Episode_number']
          : int.tryParse(json['Episode_number'].toString()) ?? 0,
      seasonId: json['Season_id'] is int
          ? json['Season_id']
          : int.tryParse(json['Season_id'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'Episode_id': episodeId,
    'Episode_number': episodeNumber,
    'Season_id': seasonId,
  };
}
