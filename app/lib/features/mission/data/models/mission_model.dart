import 'package:flutter/material.dart';

class MissionModel {
  final String id;
  final String businessId;
  final String missionType;
  final String status;
  final String? category;
  final String? region;
  final int reviewerFee;
  final int productCost;
  final DateTime? recruitmentDeadline;
  final int maxApplicants;
  final int currentApplicants;
  final String? assignedReviewerId;
  final DateTime? assignedAt;
  final DateTime? checkInTime;
  final BusinessInfo? business;
  final DateTime createdAt;
  final String visibility; // 'normal', 'hidden', 'season'
  final String? minReviewerGrade;
  final String? seasonId;
  final double bonusRate;
  final String? gpsZone; // 'green', 'yellow', 'orange', 'red'
  final String? checkinPhotoUrl;
  final bool gpsRequired;
  final String rewardType; // 'cash' | 'free_experience'
  final String? experienceDescription; // 무료체험 제공 내용
  final int? experienceValue; // 무료체험 추정 가치

  MissionModel({
    required this.id,
    required this.businessId,
    required this.missionType,
    required this.status,
    this.category,
    this.region,
    required this.reviewerFee,
    required this.productCost,
    this.recruitmentDeadline,
    required this.maxApplicants,
    this.currentApplicants = 0,
    this.assignedReviewerId,
    this.assignedAt,
    this.checkInTime,
    this.business,
    required this.createdAt,
    this.visibility = 'normal',
    this.minReviewerGrade,
    this.seasonId,
    this.bonusRate = 0,
    this.gpsZone,
    this.checkinPhotoUrl,
    this.gpsRequired = false,
    this.rewardType = 'cash',
    this.experienceDescription,
    this.experienceValue,
  });

  /// 무료체험 미션 여부
  bool get isFreeExperience => rewardType == 'free_experience';

  /// 리뷰어에게 보여줄 보상 텍스트 (예: "페이백 10,000원" / "🎁 무료체험")
  String get rewardDisplayText {
    if (isFreeExperience) {
      return experienceDescription?.isNotEmpty == true
          ? '🎁 ${experienceDescription!}'
          : '🎁 무료체험';
    }
    return '페이백 ${_formatWon(reviewerFee)}원';
  }

  static String _formatWon(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'] ?? '',
      businessId: json['business_id'] ?? json['businessId'] ?? '',
      missionType: json['mission_type'] ?? json['missionType'] ?? 'offline',
      status: json['status'] ?? 'recruiting',
      category: json['category'] ?? json['business']?['category'],
      region: json['region'] ?? json['business']?['address_city'],
      reviewerFee: json['reviewer_fee'] ?? json['reviewerFee'] ?? 0,
      productCost: json['product_cost'] ?? json['productCost'] ?? 0,
      recruitmentDeadline: json['recruitment_deadline'] != null
          ? DateTime.parse(json['recruitment_deadline'])
          : json['recruitmentDeadline'] != null
              ? DateTime.parse(json['recruitmentDeadline'])
              : null,
      maxApplicants: json['max_applicants'] ?? json['maxApplicants'] ?? 20,
      currentApplicants: json['currentApplicants'] ??
          json['recruitment']?['currentApplicants'] ??
          0,
      assignedReviewerId: json['assigned_reviewer_id'] ?? json['assignedReviewerId'],
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'])
          : json['assignedAt'] != null
              ? DateTime.parse(json['assignedAt'])
              : null,
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'])
          : json['checkInTime'] != null
              ? DateTime.parse(json['checkInTime'])
              : null,
      business: json['business'] != null
          ? BusinessInfo.fromJson(json['business'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      visibility: json['visibility'] ?? 'normal',
      minReviewerGrade: json['min_reviewer_grade'] ?? json['minReviewerGrade'],
      seasonId: json['season_id'] ?? json['seasonId'],
      bonusRate: (json['bonus_rate'] ?? json['bonusRate'] ?? 0).toDouble(),
      gpsZone: json['gps_zone'] ?? json['gpsZone'],
      checkinPhotoUrl: json['checkin_photo_url'] ?? json['checkinPhotoUrl'],
      gpsRequired: json['gps_required'] ?? json['gpsRequired'] ?? false,
      rewardType: json['reward_type'] ?? json['rewardType'] ?? 'cash',
      experienceDescription:
          json['experience_description'] ?? json['experienceDescription'],
      experienceValue: json['experience_value'] ?? json['experienceValue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'missionType': missionType,
      'status': status,
      'category': category,
      'region': region,
      'reviewerFee': reviewerFee,
      'productCost': productCost,
      'recruitmentDeadline': recruitmentDeadline?.toIso8601String(),
      'maxApplicants': maxApplicants,
      'currentApplicants': currentApplicants,
      'assignedReviewerId': assignedReviewerId,
      'visibility': visibility,
      'minReviewerGrade': minReviewerGrade,
      'seasonId': seasonId,
      'bonusRate': bonusRate,
      'gpsZone': gpsZone,
      'checkinPhotoUrl': checkinPhotoUrl,
      'gpsRequired': gpsRequired,
      'rewardType': rewardType,
      'experienceDescription': experienceDescription,
      'experienceValue': experienceValue,
    };
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending_payment':
        return '결제 대기';
      case 'recruiting':
        return '모집중';
      case 'assigned':
        return '배정됨';
      case 'in_progress':
        return '진행중';
      case 'review_submitted':
        return '리뷰 제출됨';
      case 'completed':
        return '완료';
      case 'cancelled':
        return '취소됨';
      default:
        return status;
    }
  }

  bool get isRecruiting => status == 'recruiting';
  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isHidden => visibility == 'hidden';
  bool get isSeason => visibility == 'season';

  String? get businessName => business?.name;

  int? get daysUntilDeadline {
    if (recruitmentDeadline == null) return null;
    return recruitmentDeadline!.difference(DateTime.now()).inDays;
  }

  /// Visit deadline (3 days after assignment)
  DateTime? get visitDeadline {
    if (assignedAt == null) return null;
    return assignedAt!.add(const Duration(days: 3));
  }

  /// Days until visit deadline
  int? get daysUntilVisitDeadline {
    if (visitDeadline == null) return null;
    return visitDeadline!.difference(DateTime.now()).inDays;
  }

  /// Hours until visit deadline
  int? get hoursUntilVisitDeadline {
    if (visitDeadline == null) return null;
    return visitDeadline!.difference(DateTime.now()).inHours;
  }

  // 미션 유형 한글명
  String get missionTypeDisplayName {
    switch (missionType) {
      case 'visit':
        return '방문';
      case 'delivery':
        return '배송';
      case 'online':
        return '온라인';
      case 'phone':
        return '전화';
      default:
        return missionType;
    }
  }

  // 미션 유형 아이콘
  IconData get missionTypeIcon {
    switch (missionType) {
      case 'visit':
        return Icons.store;
      case 'delivery':
        return Icons.local_shipping;
      case 'online':
        return Icons.language;
      case 'phone':
        return Icons.phone;
      default:
        return Icons.assignment;
    }
  }

  // 미션 유형 색상
  Color get missionTypeColor {
    switch (missionType) {
      case 'visit':
        return const Color(0xFF4CAF50);
      case 'delivery':
        return const Color(0xFF2196F3);
      case 'online':
        return const Color(0xFF9C27B0);
      case 'phone':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF607D8B);
    }
  }

  // 유형별 인증 요구사항 텍스트
  List<String> get verificationRequirements {
    switch (missionType) {
      case 'visit':
        return [
          '현장 사진 3장 이상',
          '영수증 필수',
          if (gpsRequired) 'GPS 위치 인증',
        ];
      case 'delivery':
        return [
          '언박싱 사진/영상',
          '배송확인 스크린샷',
          '영수증 필수',
        ];
      case 'online':
        return [
          '서비스 이용 스크린샷 3장 이상',
          '영수증 필수',
        ];
      case 'phone':
        return [
          '통화 스크린샷',
          '상담 내용 메모',
        ];
      default:
        return [];
    }
  }
}

class BusinessInfo {
  final String id;
  final String? name;
  final String? category;
  final String? addressCity;
  final String? addressFull;
  final String? addressDetail;
  final double? latitude;
  final double? longitude;

  BusinessInfo({
    required this.id,
    this.name,
    this.category,
    this.addressCity,
    this.addressFull,
    this.addressDetail,
    this.latitude,
    this.longitude,
  });

  factory BusinessInfo.fromJson(Map<String, dynamic> json) {
    return BusinessInfo(
      id: json['id'] ?? '',
      name: json['name'],
      category: json['category'],
      addressCity: json['address_city'] ?? json['addressCity'],
      addressFull: json['address_full'] ?? json['addressFull'],
      addressDetail: json['address_detail'] ?? json['addressDetail'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  /// 전체 주소 (상세 주소 포함)
  String? get address {
    if (addressFull == null) return null;
    if (addressDetail != null && addressDetail!.isNotEmpty) {
      return '$addressFull $addressDetail';
    }
    return addressFull;
  }
}
