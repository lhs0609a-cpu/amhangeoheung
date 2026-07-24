class RegionalRankingModel {
  final String? businessId;
  final String? businessName;
  final int rank;
  final double? trustScore;
  final int? reviewCount;
  final double? avgRating;
  final String? badgeLevel;
  final String? region;
  final String? category;

  RegionalRankingModel({
    this.businessId,
    this.businessName,
    required this.rank,
    this.trustScore,
    this.reviewCount,
    this.avgRating,
    this.badgeLevel,
    this.region,
    this.category,
  });

  factory RegionalRankingModel.fromJson(Map<String, dynamic> json) {
    return RegionalRankingModel(
      businessId: json['business_id'],
      businessName: json['business_name'],
      rank: json['rank'] ?? 0,
      trustScore: (json['trust_score'] ?? 0).toDouble(),
      reviewCount: json['review_count'],
      avgRating: json['avg_rating'] != null ? (json['avg_rating']).toDouble() : null,
      badgeLevel: json['badge_level'],
      region: json['region'],
      category: json['category'],
    );
  }
}

class ReviewerRankingModel {
  final String id;
  final String? nickname;
  final String? profileImage;
  final String? reviewerGrade;
  final int completedMissions;
  final double trustScore;
  final int rank;

  ReviewerRankingModel({
    required this.id,
    this.nickname,
    this.profileImage,
    this.reviewerGrade,
    this.completedMissions = 0,
    this.trustScore = 0,
    this.rank = 0,
  });

  factory ReviewerRankingModel.fromJson(Map<String, dynamic> json) {
    return ReviewerRankingModel(
      id: json['id'],
      nickname: json['nickname'],
      profileImage: json['profile_image'],
      reviewerGrade: json['reviewer_grade'],
      completedMissions: json['completed_missions'] ?? 0,
      trustScore: (json['trust_score'] ?? 0).toDouble(),
      rank: json['rank'] ?? 0,
    );
  }
}
