class Genre {
  final int genreId;
  final String genreName;
  final int isDeleted; // ✅ thêm cột này để lọc phía client

  Genre({
    required this.genreId,
    required this.genreName,
    this.isDeleted = 0,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      genreId: json['Genre_id'] is int
          ? json['Genre_id']
          : int.tryParse(json['Genre_id'].toString()) ?? 0,
      genreName: json['Genre_name']?.toString().trim() ?? '',
      isDeleted: json['is_deleted'] is int
          ? json['is_deleted']
          : int.tryParse(json['is_deleted']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'Genre_id': genreId,
    'Genre_name': genreName,
    'is_deleted': isDeleted,
  };
}
