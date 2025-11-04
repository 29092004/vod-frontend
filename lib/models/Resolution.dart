class Resolution {
  final int resolutionId;
  final String resolutionType;

  Resolution({
    required this.resolutionId,
    required this.resolutionType,
  });

  factory Resolution.fromJson(Map<String, dynamic> json) {
    return Resolution(
      resolutionId: json['Resolution_id'] is int
          ? json['Resolution_id']
          : int.tryParse(json['Resolution_id'].toString()) ?? 0,
      resolutionType: json['Resolution_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'Resolution_id': resolutionId,
    'Resolution_type': resolutionType,
  };
}
