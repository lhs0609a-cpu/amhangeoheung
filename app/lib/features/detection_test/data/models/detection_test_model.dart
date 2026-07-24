class DetectionTest {
  final String id;
  final String missionId;
  final String businessId;
  final String status; // pending, submitted, expired, skipped
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final String? guessedDate;
  final String? guessedTimeSlot;
  final String? guessedDescription;
  final int? confidenceLevel;
  final bool? dateCorrect;
  final bool? timeCorrect;
  final int? detectionScore;

  DetectionTest({
    required this.id,
    required this.missionId,
    required this.businessId,
    required this.status,
    this.expiresAt,
    this.createdAt,
    this.guessedDate,
    this.guessedTimeSlot,
    this.guessedDescription,
    this.confidenceLevel,
    this.dateCorrect,
    this.timeCorrect,
    this.detectionScore,
  });

  factory DetectionTest.fromJson(Map<String, dynamic> json) {
    return DetectionTest(
      id: json['id'] ?? '',
      missionId: json['mission_id'] ?? json['missionId'] ?? '',
      businessId: json['business_id'] ?? json['businessId'] ?? '',
      status: json['status'] ?? 'pending',
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      guessedDate: json['guessed_date'] ?? json['guessedDate'],
      guessedTimeSlot: json['guessed_time_slot'] ?? json['guessedTimeSlot'],
      guessedDescription: json['guessed_description'] ?? json['guessedDescription'],
      confidenceLevel: json['confidence_level'] ?? json['confidenceLevel'],
      dateCorrect: json['date_correct'] ?? json['dateCorrect'],
      timeCorrect: json['time_correct'] ?? json['timeCorrect'],
      detectionScore: json['detection_score'] ?? json['detectionScore'],
    );
  }

  bool get isPending => status == 'pending';

  String get remainingTime {
    if (expiresAt == null) return '';
    final remaining = expiresAt!.difference(DateTime.now());
    if (remaining.isNegative) return '만료됨';
    final hours = remaining.inHours;
    if (hours >= 24) return '${hours ~/ 24}일 ${hours % 24}시간';
    return '${hours}시간 ${remaining.inMinutes % 60}분';
  }
}

class StealthStats {
  final double stealthScore;
  final int totalTests;
  final int detectedCount;
  final int detectionRate;
  final String advice;
  final List<DetectionTest> recentTests;

  StealthStats({
    required this.stealthScore,
    required this.totalTests,
    required this.detectedCount,
    required this.detectionRate,
    required this.advice,
    required this.recentTests,
  });

  factory StealthStats.fromJson(Map<String, dynamic> json) {
    return StealthStats(
      stealthScore: (json['stealthScore'] ?? 100).toDouble(),
      totalTests: json['totalTests'] ?? 0,
      detectedCount: json['detectedCount'] ?? 0,
      detectionRate: json['detectionRate'] ?? 0,
      advice: json['advice'] ?? '',
      recentTests: (json['recentTests'] as List? ?? [])
          .map((t) => DetectionTest.fromJson(t))
          .toList(),
    );
  }
}
