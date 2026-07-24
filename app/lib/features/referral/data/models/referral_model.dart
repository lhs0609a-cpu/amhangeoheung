class ReferralModel {
  final String id;
  final String referrerId;
  final String? referredId;
  final String referralCode;
  final String status;
  final int rewardAmount;
  final DateTime createdAt;
  final DateTime? expiresAt;

  ReferralModel({
    required this.id,
    required this.referrerId,
    this.referredId,
    required this.referralCode,
    required this.status,
    this.rewardAmount = 10000,
    required this.createdAt,
    this.expiresAt,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      id: json['id'],
      referrerId: json['referrer_id'],
      referredId: json['referred_id'],
      referralCode: json['referral_code'],
      status: json['status'] ?? 'pending',
      rewardAmount: json['reward_amount'] ?? 10000,
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    );
  }
}

class ReferralStats {
  final int total;
  final int pending;
  final int registered;
  final int completed;
  final int rewarded;
  final int totalEarnings;

  ReferralStats({
    this.total = 0,
    this.pending = 0,
    this.registered = 0,
    this.completed = 0,
    this.rewarded = 0,
    this.totalEarnings = 0,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      registered: json['registered'] ?? 0,
      completed: json['completed'] ?? 0,
      rewarded: json['rewarded'] ?? 0,
      totalEarnings: json['totalEarnings'] ?? 0,
    );
  }
}

class RegionalDemand {
  final String region;
  final String? category;
  final int pendingMissions;
  final int activeReviewers;
  final int demandScore;

  RegionalDemand({
    required this.region,
    this.category,
    this.pendingMissions = 0,
    this.activeReviewers = 0,
    this.demandScore = 0,
  });

  factory RegionalDemand.fromJson(Map<String, dynamic> json) {
    return RegionalDemand(
      region: json['region'] ?? '',
      category: json['category'],
      pendingMissions: json['pending_missions'] ?? 0,
      activeReviewers: json['active_reviewers'] ?? 0,
      demandScore: json['demand_score'] ?? 0,
    );
  }
}
