class FilmActor {
  final int filmId;
  final int actorId;
  final String characterName;

  FilmActor({
    required this.filmId,
    required this.actorId,
    required this.characterName,
  });

  factory FilmActor.fromJson(Map<String, dynamic> json) {
    return FilmActor(
      filmId: json['Film_id'] is int
          ? json['Film_id']
          : int.tryParse(json['Film_id'].toString()) ?? 0,
      actorId: json['Actor_id'] is int
          ? json['Actor_id']
          : int.tryParse(json['Actor_id'].toString()) ?? 0,
      characterName: json['Character_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'Film_id': filmId,
    'Actor_id': actorId,
    'Character_name': characterName,
  };
}
