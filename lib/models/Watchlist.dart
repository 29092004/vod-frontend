class WatchList {
  final int watchListId;
  final int profileId;
  final String createAt;
  final String watchListName;

  WatchList({
    required this.watchListId,
    required this.profileId,
    required this.createAt,
    required this.watchListName,
  });

  factory WatchList.fromJson(Map<String, dynamic> json) {
    return WatchList(
      watchListId: json['WatchList_id'] is int
          ? json['WatchList_id']
          : int.tryParse(json['WatchList_id'].toString()) ?? 0,
      profileId: json['Profile_id'] is int
          ? json['Profile_id']
          : int.tryParse(json['Profile_id'].toString()) ?? 0,
      createAt: json['Create_at'] ?? '',
      watchListName: json['WatchList_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'WatchList_id': watchListId,
    'Profile_id': profileId,
    'Create_at': createAt,
    'WatchList_name': watchListName,
  };
}
