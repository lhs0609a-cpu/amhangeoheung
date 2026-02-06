class UserModel {
  final String id;
  final String email;
  final String name;
  final String? nickname;
  final String userType;
  final String? profileImage;
  final bool isVerified;
  final ReviewerInfo? reviewer;
  final PremiumInfo? premium;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.nickname,
    required this.userType,
    this.profileImage,
    required this.isVerified,
    this.reviewer,
    this.premium,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      nickname: json['nickname'],
      userType: json['userType'] ?? 'consumer',
      profileImage: json['profileImage'],
      isVerified: json['isVerified'] ?? false,
      reviewer: json['reviewer'] != null
          ? ReviewerInfo.fromJson(json['reviewer'])
          : null,
      premium: json['premium'] != null
          ? PremiumInfo.fromJson(json['premium'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'nickname': nickname,
      'userType': userType,
      'profileImage': profileImage,
      'isVerified': isVerified,
      'reviewer': reviewer?.toJson(),
      'premium': premium?.toJson(),
    };
  }

  bool get isReviewer => userType == 'reviewer';
  bool get isBusiness => userType == 'business';
  bool get isConsumer => userType == 'consumer';
}

class ReviewerInfo {
  final String grade;
  final int completedMissions;
  final double trustScore;
  final List<String>? specialties;

  ReviewerInfo({
    required this.grade,
    required this.completedMissions,
    required this.trustScore,
    this.specialties,
  });

  factory ReviewerInfo.fromJson(Map<String, dynamic> json) {
    return ReviewerInfo(
      grade: json['grade'] ?? 'rookie',
      completedMissions: json['completedMissions'] ?? 0,
      trustScore: (json['trustScore'] ?? 0).toDouble(),
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grade': grade,
      'completedMissions': completedMissions,
      'trustScore': trustScore,
      'specialties': specialties,
    };
  }

  String get gradeDisplayName {
    switch (grade) {
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

class PremiumInfo {
  final bool isActive;
  final DateTime? expiresAt;

  PremiumInfo({
    required this.isActive,
    this.expiresAt,
  });

  factory PremiumInfo.fromJson(Map<String, dynamic> json) {
    return PremiumInfo(
      isActive: json['isActive'] ?? false,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}
