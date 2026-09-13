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
  final String? phone;
  final String? bankName;
  final String? bankAccount;
  final String? bankHolder;

  ReviewerInfo? get reviewerInfo => reviewer;
  PremiumInfo? get premiumInfo => premium;

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
    this.phone,
    this.bankName,
    this.bankAccount,
    this.bankHolder,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      nickname: json['nickname'],
      userType: json['userType'] ?? json['user_type'] ?? 'consumer',
      profileImage: json['profileImage'] ?? json['profile_image'],
      isVerified: json['isVerified'] ?? json['is_verified'] ?? false,
      phone: json['phone'],
      bankName: json['bankName'] ?? json['bank_name'],
      bankAccount: json['bankAccount'] ??
          json['bank_account'] ??
          json['bank_account_number'],
      bankHolder: json['bankHolder'] ??
          json['bank_holder'] ??
          json['bank_account_holder'],
      reviewer: json['reviewer'] != null
          ? ReviewerInfo.fromJson(json['reviewer'])
          : (json['user_type'] ?? json['userType']) == 'reviewer'
              ? ReviewerInfo.fromJson(json)
              : null,
      premium: json['premium'] != null
          ? PremiumInfo.fromJson(json['premium'])
          : json.containsKey('premium_active')
              ? PremiumInfo.fromJson({
                  'isActive': json['premium_active'],
                  'expiresAt': json['premium_expires_at'],
                  'planName': json['premium_plan'],
                })
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
      'phone': phone,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'bankHolder': bankHolder,
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
      grade: json['grade'] ?? json['reviewer_grade'] ?? 'rookie',
      completedMissions:
          json['completedMissions'] ?? json['completed_missions'] ?? 0,
      trustScore: (json['trustScore'] ?? json['trust_score'] ?? 0).toDouble(),
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
  final String? planName;

  PremiumInfo({
    required this.isActive,
    this.expiresAt,
    this.planName,
  });

  factory PremiumInfo.fromJson(Map<String, dynamic> json) {
    return PremiumInfo(
      isActive: json['isActive'] ?? false,
      planName: json['planName'],
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'planName': planName,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}
