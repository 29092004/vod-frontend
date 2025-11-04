class Favorite {
  final int profileId;
  final int filmId;

  Favorite({
    required this.profileId,
    required this.filmId,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      profileId: json['Profile_id'] is int
          ? json['Profile_id']
          : int.tryParse(json['Profile_id'].toString()) ?? 0,
      filmId: json['Film_id'] is int
          ? json['Film_id']
          : int.tryParse(json['Film_id'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'Profile_id': profileId,
    'Film_id': filmId,
  };
}
