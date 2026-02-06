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
  final BusinessInfo? business;
  final DateTime createdAt;

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
    this.business,
    required this.createdAt,
  });

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
      business: json['business'] != null
          ? BusinessInfo.fromJson(json['business'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
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

  String? get businessName => business?.name;
  DateTime? get assignedAt => createdAt;

  int? get daysUntilDeadline {
    if (recruitmentDeadline == null) return null;
    return recruitmentDeadline!.difference(DateTime.now()).inDays;
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
