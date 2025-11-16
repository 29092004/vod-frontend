class WatchList {
  final int id;
  final int profileId;
  final String name;
  final DateTime? createdAt;

  WatchList({
    required this.id,
    required this.profileId,
    required this.name,
    this.createdAt,
  });

  factory WatchList.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return WatchList(
      id: parseInt(json['WatchList_id']),
      profileId: parseInt(json['Profile_id']),
      name: json['WatchList_name']?.toString() ?? '',
      createdAt: parseDate(json['Create_at']),
    );
  }
}
