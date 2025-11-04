class Season {
  final int seasonId;
  final String seasonName;
  final int filmId;

  Season({
    required this.seasonId,
    required this.seasonName,
    required this.filmId,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      seasonId: json['Season_id'] is int
          ? json['Season_id']
          : int.tryParse(json['Season_id'].toString()) ?? 0,
      seasonName: json['Season_name'] ?? '',
      filmId: json['Film_id'] is int
          ? json['Film_id']
          : int.tryParse(json['Film_id'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'Season_id': seasonId,
    'Season_name': seasonName,
    'Film_id': filmId,
  };
}
