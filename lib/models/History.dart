class History {
  final int historyId;
  final int profileId;
  final int filmId;
  final int episodeId;
  final int positionSeconds;
  final int durationSeconds;
  final String lastWatched;

  History({
    required this.historyId,
    required this.profileId,
    required this.filmId,
    required this.episodeId,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.lastWatched,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      historyId: json['History_id'] is int
          ? json['History_id']
          : int.tryParse(json['History_id'].toString()) ?? 0,
      profileId: json['Profile_id'] is int
          ? json['Profile_id']
          : int.tryParse(json['Profile_id'].toString()) ?? 0,
      filmId: json['Film_id'] is int
          ? json['Film_id']
          : int.tryParse(json['Film_id'].toString()) ?? 0,
      episodeId: json['Episode_id'] is int
          ? json['Episode_id']
          : int.tryParse(json['Episode_id'].toString()) ?? 0,
      positionSeconds: json['position_seconds'] is int
          ? json['position_seconds']
          : int.tryParse(json['position_seconds'].toString()) ?? 0,
      durationSeconds: json['duration_seconds'] is int
          ? json['duration_seconds']
          : int.tryParse(json['duration_seconds'].toString()) ?? 0,
      lastWatched: json['last_watched'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'History_id': historyId,
    'Profile_id': profileId,
    'Film_id': filmId,
    'Episode_id': episodeId,
    'position_seconds': positionSeconds,
    'duration_seconds': durationSeconds,
    'last_watched': lastWatched,
  };
}
