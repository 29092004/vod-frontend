class WatchListItem {
  final int watchListId;
  final int filmId;
  final String addAt;

  WatchListItem({
    required this.watchListId,
    required this.filmId,
    required this.addAt,
  });

  factory WatchListItem.fromJson(Map<String, dynamic> json) {
    return WatchListItem(
      watchListId: json['WatchList_id'] is int
          ? json['WatchList_id']
          : int.tryParse(json['WatchList_id'].toString()) ?? 0,
      filmId: json['Film_id'] is int
          ? json['Film_id']
          : int.tryParse(json['Film_id'].toString()) ?? 0,
      addAt: json['Add_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'WatchList_id': watchListId,
    'Film_id': filmId,
    'Add_at': addAt,
  };
}
