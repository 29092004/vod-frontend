class Country {
  final int countryId;
  final String countryName;

  Country({
    required this.countryId,
    required this.countryName,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      countryId: json['Country_id'] is int
          ? json['Country_id']
          : int.tryParse(json['Country_id'].toString()) ?? 0,
      countryName: json['Country_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'Country_id': countryId,
    'Country_name': countryName,
  };
}
