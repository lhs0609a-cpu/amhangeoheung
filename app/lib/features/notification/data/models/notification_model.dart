class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    this.readAt,
    this.data = const {},
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'general',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      data: json['data'] is Map<String, dynamic>
          ? json['data']
          : <String, dynamic>{},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}주 전';
    return '${(diff.inDays / 30).floor()}개월 전';
  }
}
