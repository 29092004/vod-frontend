class Actor {
  final int actorId;
  final String actorName;
  final String actorGender;
  final String actorAvatar;

  Actor({
    required this.actorId,
    required this.actorName,
    required this.actorGender,
    required this.actorAvatar,
  });

  factory Actor.fromJson(Map<String, dynamic> json) {
    return Actor(
      actorId: json['Actor_id'] is int
          ? json['Actor_id']
          : int.tryParse(json['Actor_id'].toString()) ?? 0,
      actorName: json['Actor_name'] ?? '',
      actorGender: json['Actor_gender'] ?? '',
      actorAvatar: json['Actor_avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'Actor_id': actorId,
    'Actor_name': actorName,
    'Actor_gender': actorGender,
    'Actor_avatar': actorAvatar,
  };
}
