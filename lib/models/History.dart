class History {
  final int historyId;
  final int filmId;
  final String filmName;
  final int? episodeId;
  final int? episodeNumber;
  int positionSeconds; // ✅ có thể thay đổi được
  int durationSeconds; // ✅ có thể thay đổi được
  String posterUrl;
  DateTime lastWatched;

  History({
    required this.historyId,
    required this.filmId,
    required this.filmName,
    this.episodeId,
    this.episodeNumber,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.posterUrl,
    required this.lastWatched,
  });

  /// ✅ Tiện ích tính phần trăm tiến độ xem
  double get progressPercent =>
      durationSeconds == 0 ? 0 : positionSeconds / durationSeconds;

  /// ✅ Cập nhật tiến độ mới (dễ gọi từ màn hình Xem tiếp)
  void updateProgress(int newPosition, int newDuration) {
    positionSeconds = newPosition;
    durationSeconds = newDuration;
    lastWatched = DateTime.now();
  }

  /// ✅ Parse từ JSON
  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      historyId: json['History_id'],
      filmId: json['Film_id'],
      filmName: json['Film_name'] ?? '',
      episodeId: json['Episode_id'],
      episodeNumber: json['Episode_number'],
      positionSeconds: json['position_seconds'] ?? 0,
      durationSeconds: json['duration_seconds'] ?? 0,
      posterUrl: json['poster_url'] ?? '',
      lastWatched: DateTime.tryParse(json['last_watched'] ?? '') ??
          DateTime.now(),
    );
  }

  /// ✅ Chuyển về JSON (nếu cần gửi lại server)
  Map<String, dynamic> toJson() {
    return {
      'History_id': historyId,
      'Film_id': filmId,
      'Film_name': filmName,
      'Episode_id': episodeId,
      'Episode_number': episodeNumber,
      'position_seconds': positionSeconds,
      'duration_seconds': durationSeconds,
      'poster_url': posterUrl,
      'last_watched': lastWatched.toIso8601String(),
    };
  }
}
