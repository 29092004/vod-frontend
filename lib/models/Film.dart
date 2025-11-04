class Film {
  final int filmId;
  final String filmName;
  final bool isSeries;

  Film({
    required this.filmId,
    required this.filmName,
    required this.isSeries,
  });

  factory Film.fromJson(Map<String, dynamic> json) {
    return Film(
      filmId: json['Film_id'] is int
          ? json['Film_id']
          : int.tryParse(json['Film_id'].toString()) ?? 0,
      filmName: json['Film_name'] ?? '',
      isSeries: json['is_series'] == 1 || json['is_series'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'Film_id': filmId,
    'Film_name': filmName,
    'is_series': isSeries ? 1 : 0,
  };
}
