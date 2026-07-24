class ReviewRequestModel {
  final String id;
  final String? requesterId;
  final String businessId;
  final String? businessName;
  final String? category;
  final String? region;
  final String? message;
  final String status;
  final DateTime createdAt;

  ReviewRequestModel({
    required this.id,
    this.requesterId,
    required this.businessId,
    this.businessName,
    this.category,
    this.region,
    this.message,
    this.status = 'pending',
    required this.createdAt,
  });

  factory ReviewRequestModel.fromJson(Map<String, dynamic> json) {
    return ReviewRequestModel(
      id: json['id'],
      requesterId: json['requester_id'],
      businessId: json['business_id'],
      businessName: json['business_name'],
      category: json['category'],
      region: json['region'],
      message: json['message'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
