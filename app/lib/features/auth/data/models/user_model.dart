class UserModel {
  final String id;
  final String email;
  final String name;
  final String? nickname;
  final String userType;
  final String? profileImage;
  final bool isVerified;
  final String? phone;
  final ReviewerInfo? reviewer;
  final PremiumInfo? premium;

  // 정산 계좌. /users/me 는 DB 행을 그대로 내려주므로 snake_case 로 온다.
  final String? bankName;
  final String? bankAccount;
  final String? bankHolder;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.nickname,
    required this.userType,
    this.profileImage,
    required this.isVerified,
    this.phone,
    this.reviewer,
    this.premium,
    this.bankName,
    this.bankAccount,
    this.bankHolder,
  });

  /// 백엔드가 camelCase 와 snake_case 를 혼용해 내려주므로 둘 다 받아준다.
  static String? _pick(Map<String, dynamic> json, String camel, String snake) {
    final value = json[camel] ?? json[snake];
    return value is String && value.isNotEmpty ? value : null;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      nickname: json['nickname'],
      userType: json['userType'] ?? json['user_type'] ?? 'consumer',
      profileImage: _pick(json, 'profileImage', 'profile_image'),
      isVerified: json['isVerified'] ?? json['is_verified'] ?? false,
      phone: _pick(json, 'phone', 'phone_number'),
      reviewer: json['reviewer'] != null
          ? ReviewerInfo.fromJson(json['reviewer'])
          : null,
      premium: json['premium'] != null
          ? PremiumInfo.fromJson(json['premium'])
          : null,
      bankName: _pick(json, 'bankName', 'bank_name'),
      bankAccount: _pick(json, 'bankAccount', 'bank_account'),
      bankHolder: _pick(json, 'bankHolder', 'bank_holder'),
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
      'phone': phone,
      'reviewer': reviewer?.toJson(),
      'premium': premium?.toJson(),
      'bankName': bankName,
      'bankAccount': bankAccount,
      'bankHolder': bankHolder,
    };
  }

  bool get isReviewer => userType == 'reviewer';
  bool get isBusiness => userType == 'business';
  bool get isConsumer => userType == 'consumer';

  /// 화면에 보여줄 이름. 닉네임이 있으면 우선한다.
  String get displayName =>
      (nickname != null && nickname!.isNotEmpty) ? nickname! : name;

  /// 정산 계좌 등록 여부
  bool get hasBankAccount =>
      bankName != null && bankAccount != null && bankAccount!.isNotEmpty;

  /// 계좌번호 마스킹 표시 (예: "국민 ****1234")
  String get maskedBankAccount {
    if (!hasBankAccount) return '미등록';
    final digits = bankAccount!;
    final tail = digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
    return '${bankName ?? ''} ****$tail'.trim();
  }

  // 화면 코드가 쓰는 별칭. 필드명을 바꾸면 호출부가 전부 깨지므로 게터로 흡수한다.
  ReviewerInfo? get reviewerInfo => reviewer;
  PremiumInfo? get premiumInfo => premium;
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

  /// 구독 중인 요금제 표시명. 백엔드가 planName 으로 내려준다.
  final String? planName;

  PremiumInfo({
    required this.isActive,
    this.expiresAt,
    this.planName,
  });

  factory PremiumInfo.fromJson(Map<String, dynamic> json) {
    final rawExpiresAt = json['expiresAt'] ?? json['expires_at'];
    return PremiumInfo(
      isActive: json['isActive'] ?? json['is_active'] ?? false,
      // 서버가 잘못된 날짜 문자열을 보내도 프로필 화면 전체가 죽지 않게 한다.
      expiresAt: rawExpiresAt is String ? DateTime.tryParse(rawExpiresAt) : null,
      planName: json['planName'] ?? json['plan_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'expiresAt': expiresAt?.toIso8601String(),
      'planName': planName,
    };
  }

  /// 남은 구독 일수. 만료일이 없거나 지났으면 0.
  int daysRemaining(DateTime now) {
    if (expiresAt == null) return 0;
    final diff = expiresAt!.difference(now).inDays;
    return diff > 0 ? diff : 0;
  }
}
