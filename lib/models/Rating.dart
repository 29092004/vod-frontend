class Rating {
  final int profileId;
  final int filmId;
  final double score;
  final String review;

  Rating({
    required this.profileId,
    required this.filmId,
    required this.score,
    required this.review,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      profileId: json['Profile_id'] is int
          ? json['Profile_id']
          : int.tryParse(json['Profile_id'].toString()) ?? 0,
      filmId: json['Film_id'] is int
          ? json['Film_id']
          : int.tryParse(json['Film_id'].toString()) ?? 0,
      score: (json['Score'] is num)
          ? json['Score'].toDouble()
          : double.tryParse(json['Score'].toString()) ?? 0.0,
      review: json['Review'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'Profile_id': profileId,
    'Film_id': filmId,
    'Score': score,
    'Review': review,
  };
}
