
class Poster {
  final int posterId;
  final int posterTypeId;
  final String posterUrl;
  final int filmId;

  Poster({
    required this.posterId,
    required this.posterTypeId,
    required this.posterUrl,
    required this.filmId,
  });

  factory Poster.fromJson(Map<String, dynamic> json) {
    return Poster(
      posterId: json['Poster_id'] is int
          ? json['Poster_id']
          : int.tryParse(json['Poster_id'].toString()) ?? 0,
      posterTypeId: json['Postertype_id'] is int
          ? json['Postertype_id']
          : int.tryParse(json['Postertype_id'].toString()) ?? 0,
      posterUrl: json['Poster_url'] ?? '',
      filmId: json['Film_id'] is int
          ? json['Film_id']
          : int.tryParse(json['Film_id'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'Poster_id': posterId,
    'Postertype_id': posterTypeId,
    'Poster_url': posterUrl,
    'Film_id': filmId,
  };
}
