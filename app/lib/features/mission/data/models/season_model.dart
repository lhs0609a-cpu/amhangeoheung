class SeasonModel {
  final String id;
  final String name;
  final String theme;
  final String? description;
  final String? bannerImage;
  final DateTime startAt;
  final DateTime endAt;
  final double rewardBonusRate;
  final String minGrade;
  final bool isActive;

  SeasonModel({
    required this.id,
    required this.name,
    required this.theme,
    this.description,
    this.bannerImage,
    required this.startAt,
    required this.endAt,
    this.rewardBonusRate = 0,
    this.minGrade = 'rookie',
    this.isActive = true,
  });

  factory SeasonModel.fromJson(Map<String, dynamic> json) {
    return SeasonModel(
      id: json['id'],
      name: json['name'],
      theme: json['theme'],
      description: json['description'],
      bannerImage: json['banner_image'],
      startAt: DateTime.parse(json['start_at']),
      endAt: DateTime.parse(json['end_at']),
      rewardBonusRate: (json['reward_bonus_rate'] ?? 0).toDouble(),
      minGrade: json['min_grade'] ?? 'rookie',
      isActive: json['is_active'] ?? true,
    );
  }

  Duration get remainingTime => endAt.difference(DateTime.now());
  bool get isExpired => DateTime.now().isAfter(endAt);
}
