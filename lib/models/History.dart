class History {
  final int historyId;
  final int filmId;
  final String filmName;        // Tên tiếng Việt
  final String originalName;    // 🔥 Thêm tên tiếng Anh
  final int? episodeId;
  final int? episodeNumber;

  int positionSeconds;
  int durationSeconds;
  String posterUrl;
  DateTime lastWatched;

  History({
    required this.historyId,
    required this.filmId,
    required this.filmName,
    required this.originalName,  // 🔥 bắt buộc truyền vào
    this.episodeId,
    this.episodeNumber,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.posterUrl,
    required this.lastWatched,
  });

  double get progressPercent =>
      durationSeconds == 0 ? 0 : positionSeconds / durationSeconds;

  void updateProgress(int newPosition, int newDuration) {
    positionSeconds = newPosition;
    durationSeconds = newDuration;
    lastWatched = DateTime.now();
  }

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      historyId: json['History_id'],
      filmId: json['Film_id'],
      filmName: json['Film_name'] ?? '',
      originalName: json['Original_name'] ?? '',   // 🔥 lấy từ API
      episodeId: json['Episode_id'],
      episodeNumber: json['Episode_number'],
      positionSeconds: json['position_seconds'] ?? 0,
      durationSeconds: json['duration_seconds'] ?? 0,
      posterUrl: json['poster_url'] ?? '',
      lastWatched: DateTime.tryParse(json['last_watched'] ?? '')
          ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'History_id': historyId,
      'Film_id': filmId,
      'Film_name': filmName,
      'Original_name': originalName,      // 🔥 thêm vào JSON
      'Episode_id': episodeId,
      'Episode_number': episodeNumber,
      'position_seconds': positionSeconds,
      'duration_seconds': durationSeconds,
      'poster_url': posterUrl,
      'last_watched': lastWatched.toIso8601String(),
    };
  }
}
