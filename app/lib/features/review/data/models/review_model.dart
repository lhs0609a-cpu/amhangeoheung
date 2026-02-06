class ReviewModel {
  final String id;
  final String missionId;
  final String businessId;
  final String reviewerId;
  final String status;
  final double totalScore;
  final String? summary;
  final List<String> pros;
  final List<String> cons;
  final String? detailedReview;
  final int helpfulCount;
  final int notHelpfulCount;
  final BusinessInfo? business;
  final ReviewerInfo? reviewer;
  final List<ReviewPhoto> photos;
  final Map<String, int>? scores;
  final DateTime? publishedAt;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.missionId,
    required this.businessId,
    required this.reviewerId,
    required this.status,
    required this.totalScore,
    this.summary,
    this.pros = const [],
    this.cons = const [],
    this.detailedReview,
    this.helpfulCount = 0,
    this.notHelpfulCount = 0,
    this.business,
    this.reviewer,
    this.photos = const [],
    this.scores,
    this.publishedAt,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      missionId: json['mission_id'] ?? json['missionId'] ?? '',
      businessId: json['business_id'] ?? json['businessId'] ?? '',
      reviewerId: json['reviewer_id'] ?? json['reviewerId'] ?? '',
      status: json['status'] ?? 'draft',
      totalScore: (json['total_score'] ?? json['totalScore'] ?? 0).toDouble(),
      summary: json['summary'] ?? json['content_summary'],
      pros: json['pros'] != null
          ? List<String>.from(json['pros'])
          : json['content_pros'] != null
              ? List<String>.from(json['content_pros'])
              : [],
      cons: json['cons'] != null
          ? List<String>.from(json['cons'])
          : json['content_cons'] != null
              ? List<String>.from(json['content_cons'])
              : [],
      detailedReview: json['detailed_review'] ?? json['detailedReview'],
      helpfulCount: json['helpful_count'] ?? json['helpfulCount'] ?? 0,
      notHelpfulCount: json['not_helpful_count'] ?? json['notHelpfulCount'] ?? 0,
      business: json['business'] != null
          ? BusinessInfo.fromJson(json['business'])
          : null,
      reviewer: json['reviewer'] != null
          ? ReviewerInfo.fromJson(json['reviewer'])
          : null,
      photos: json['photos'] != null
          ? (json['photos'] as List).map((p) => ReviewPhoto.fromJson(p)).toList()
          : [],
      scores: json['scores'] != null
          ? Map<String, int>.from(
              (json['scores'] as List).fold<Map<String, int>>(
                {},
                (map, item) {
                  map[item['category'] ?? item['criteria_name']] =
                      item['score'] ?? 0;
                  return map;
                },
              ),
            )
          : null,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  String get statusDisplayName {
    switch (status) {
      case 'draft':
        return '작성중';
      case 'submitted':
        return '제출됨';
      case 'preview':
        return '선공개';
      case 'published':
        return '공개됨';
      case 'disputed':
        return '이의제기';
      default:
        return status;
    }
  }
}

class BusinessInfo {
  final String id;
  final String? name;
  final String? category;
  final String? addressCity;
  final String? badgeLevel;

  BusinessInfo({
    required this.id,
    this.name,
    this.category,
    this.addressCity,
    this.badgeLevel,
  });

  factory BusinessInfo.fromJson(Map<String, dynamic> json) {
    return BusinessInfo(
      id: json['id'] ?? '',
      name: json['name'],
      category: json['category'],
      addressCity: json['address_city'] ?? json['addressCity'],
      badgeLevel: json['badge_level'] ?? json['badgeLevel'],
    );
  }

  String get badgeDisplayName {
    switch (badgeLevel) {
      case 'platinum':
        return '플래티넘';
      case 'gold':
        return '골드';
      case 'silver':
        return '실버';
      case 'bronze':
        return '브론즈';
      default:
        return '';
    }
  }
}

class ReviewerInfo {
  final String id;
  final String? nickname;
  final String? reviewerGrade;

  ReviewerInfo({
    required this.id,
    this.nickname,
    this.reviewerGrade,
  });

  factory ReviewerInfo.fromJson(Map<String, dynamic> json) {
    return ReviewerInfo(
      id: json['id'] ?? '',
      nickname: json['nickname'],
      reviewerGrade: json['reviewer_grade'] ?? json['reviewerGrade'],
    );
  }

  String get gradeDisplayName {
    switch (reviewerGrade) {
      case 'master':
        return '마스터';
      case 'senior':
        return '시니어';
      case 'regular':
        return '정규';
      default:
        return '루키';
    }
  }
}

class ReviewPhoto {
  final String url;
  final String? caption;

  ReviewPhoto({
    required this.url,
    this.caption,
  });

  factory ReviewPhoto.fromJson(Map<String, dynamic> json) {
    return ReviewPhoto(
      url: json['url'] ?? json['photo_url'] ?? '',
      caption: json['caption'],
    );
  }
}
