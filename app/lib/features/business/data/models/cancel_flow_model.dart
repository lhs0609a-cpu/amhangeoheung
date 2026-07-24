class CancelInitiateResponse {
  final int totalReviews;
  final double avgRating;
  final String badgeLevel;
  final int subscriptionMonths;
  final String? badgeLossWarning;
  final String? reviewExpiryWarning;
  final int estimatedRevenueLoss;

  CancelInitiateResponse({
    required this.totalReviews,
    required this.avgRating,
    required this.badgeLevel,
    required this.subscriptionMonths,
    this.badgeLossWarning,
    this.reviewExpiryWarning,
    required this.estimatedRevenueLoss,
  });

  factory CancelInitiateResponse.fromJson(Map<String, dynamic> json) {
    return CancelInitiateResponse(
      totalReviews: json['totalReviews'] ?? 0,
      avgRating: (json['avgRating'] ?? 0).toDouble(),
      badgeLevel: json['badgeLevel'] ?? 'none',
      subscriptionMonths: json['subscriptionMonths'] ?? 0,
      badgeLossWarning: json['badgeLossWarning'],
      reviewExpiryWarning: json['reviewExpiryWarning'],
      estimatedRevenueLoss: json['estimatedRevenueLoss'] ?? 0,
    );
  }
}

class CancelReason {
  final String category;
  final String? detail;

  CancelReason({required this.category, this.detail});

  static const List<Map<String, String>> categories = [
    {'key': 'too_expensive', 'label': '비용이 너무 높아요'},
    {'key': 'not_useful', 'label': '효과를 못 느꼈어요'},
    {'key': 'found_alternative', 'label': '다른 서비스를 찾았어요'},
    {'key': 'temporary_closure', 'label': '업체를 일시 휴업해요'},
    {'key': 'other', 'label': '기타'},
  ];
}
