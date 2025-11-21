class Film {
  final int filmId;
  final String filmName;
  final bool isSeries;
  final bool isPremiumOnly;

  Film({
    required this.filmId,
    required this.filmName,
    required this.isSeries,
    required this.isPremiumOnly,
  });

  factory Film.fromJson(Map<String, dynamic> json) {
    return Film(
      filmId: json['Film_id'] is int
          ? json['Film_id']
          : int.tryParse(json['Film_id'].toString()) ?? 0,
      filmName: json['Film_name'] ?? '',
      isSeries: json['is_series'] == 1 || json['is_series'] == true,
      isPremiumOnly: json['is_premium_only'] == 1 || json['is_premium_only'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'Film_id': filmId,
    'Film_name': filmName,
    'is_series': isSeries ? 1 : 0,
    'is_premium_only': isPremiumOnly ? 1 : 0,
  };
}
