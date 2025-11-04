class Profile {
  final int profileId;
  final String profileName;
  final String avatarUrl;
  final int accountId;

  Profile({
    required this.profileId,
    required this.profileName,
    required this.avatarUrl,
    required this.accountId,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      profileId: json['Profile_id'] is int
          ? json['Profile_id']
          : int.tryParse(json['Profile_id'].toString()) ?? 0,
      profileName: json['Profile_name'] ?? '',
      avatarUrl: json['Avatar_url'] ?? '',
      accountId: json['Account_id'] is int
          ? json['Account_id']
          : int.tryParse(json['Account_id'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'Profile_id': profileId,
    'Profile_name': profileName,
    'Avatar_url': avatarUrl,
    'Account_id': accountId,
  };
}
