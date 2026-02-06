import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../../../core/network/api_client.dart';

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] is Map<String, dynamic>
          ? json['data']
          : const {},
      isRead: json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiClient _apiClient = ApiClient();
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _page = 1;
    });

    try {
      final response = await _apiClient.get(
        '/notifications',
        queryParameters: {'page': 1, 'limit': 20},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final items = (response.data['data']?['notifications'] as List? ?? [])
            .map((json) => NotificationItem.fromJson(json))
            .toList();

        setState(() {
          _notifications = items;
          _isLoading = false;
          _hasMore = items.length >= 20;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = response.data['message'] ?? '알림을 불러올 수 없습니다';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '알림을 불러올 수 없습니다';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _page + 1;
      final response = await _apiClient.get(
        '/notifications',
        queryParameters: {'page': nextPage, 'limit': 20},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final items = (response.data['data']?['notifications'] as List? ?? [])
            .map((json) => NotificationItem.fromJson(json))
            .toList();

        setState(() {
          _notifications.addAll(items);
          _page = nextPage;
          _hasMore = items.length >= 20;
          _isLoadingMore = false;
        });
      } else {
        setState(() => _isLoadingMore = false);
      }
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _apiClient.put('/notifications/$notificationId/read');
      setState(() {
        final index =
            _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final old = _notifications[index];
          _notifications[index] = NotificationItem(
            id: old.id,
            type: old.type,
            title: old.title,
            message: old.message,
            data: old.data,
            isRead: true,
            createdAt: old.createdAt,
          );
        }
      });
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await _apiClient.put('/notifications/read-all');
      setState(() {
        _notifications = _notifications
            .map((n) => NotificationItem(
                  id: n.id,
                  type: n.type,
                  title: n.title,
                  message: n.message,
                  data: n.data,
                  isRead: true,
                  createdAt: n.createdAt,
                ))
            .toList();
      });
    } catch (_) {}
  }

  void _navigateToDetail(NotificationItem notification) {
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }

    final data = notification.data;
    switch (notification.type) {
      case 'mission_selected':
      case 'mission_new':
        final missionId = data['missionId'];
        if (missionId != null) context.push('/missions/$missionId');
        break;
      case 'review_published':
      case 'review_submitted':
        final reviewId = data['reviewId'];
        if (reviewId != null) context.push('/reviews/$reviewId');
        break;
      case 'settlement_complete':
        context.push('/settlements');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('알림', style: HwahaeTypography.titleMedium),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                '모두 읽음',
                style: HwahaeTypography.labelMedium.copyWith(
                  color: HwahaeColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: HwahaeColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? '알림을 불러올 수 없습니다',
              style: HwahaeTypography.bodyMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none,
                size: 64, color: HwahaeColors.textTertiary),
            const SizedBox(height: 16),
            Text('알림이 없습니다', style: HwahaeTypography.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '새로운 알림이 오면 여기에 표시됩니다',
              style: HwahaeTypography.bodyMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: HwahaeColors.primary,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildNotificationTile(_notifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem notification) {
    return InkWell(
      onTap: () => _navigateToDetail(notification),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: notification.isRead
            ? HwahaeColors.surface
            : HwahaeColors.primary.withOpacity(0.04),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getTypeColor(notification.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getTypeIcon(notification.type),
                color: _getTypeColor(notification.type),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: HwahaeTypography.titleSmall.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: HwahaeColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: HwahaeTypography.bodySmall.copyWith(
                      color: HwahaeColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTimeAgo(notification.createdAt),
                    style: HwahaeTypography.captionSmall.copyWith(
                      color: HwahaeColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'mission_selected':
        return Icons.flag_rounded;
      case 'mission_new':
        return Icons.campaign_rounded;
      case 'review_published':
      case 'review_submitted':
        return Icons.rate_review_rounded;
      case 'settlement_complete':
        return Icons.account_balance_wallet;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'mission_selected':
      case 'mission_new':
        return HwahaeColors.warning;
      case 'review_published':
      case 'review_submitted':
        return HwahaeColors.primary;
      case 'settlement_complete':
        return HwahaeColors.success;
      default:
        return HwahaeColors.textSecondary;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}주 전';
    return '${diff.inDays ~/ 30}개월 전';
  }
}
