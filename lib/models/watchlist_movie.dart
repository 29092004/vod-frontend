class WatchListMovie {
  final int filmId;
  final String name;
  final bool isSeries;
  final String? posterUrl;
  final DateTime? addedAt;

  WatchListMovie({
    required this.filmId,
    required this.name,
    required this.isSeries,
    this.posterUrl,
    this.addedAt,
  });

  factory WatchListMovie.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    bool parseBool(dynamic v) {
      if (v is bool) return v;
      if (v == 1 || v == '1' || v == true) return true;
      return false;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return WatchListMovie(
      filmId: parseInt(json['Film_id'] ?? json['film_id']),
      name: json['Film_name']?.toString() ?? json['name']?.toString() ?? '',
      isSeries: parseBool(json['is_series']),
      posterUrl:
          json['Poster_url']?.toString() ?? json['poster_url']?.toString(),
      addedAt: parseDate(json['Add_at'] ?? json['add_at']),
    );
  }
}
