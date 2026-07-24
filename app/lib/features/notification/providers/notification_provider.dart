import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/models/notification_model.dart';

// Notification State
class NotificationState {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final int unreadCount;
  final String? error;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.error,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    int? unreadCount,
    String? error,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      error: error,
    );
  }
}

// Notification Notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState());

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiClient.instance.dio.get('/notifications');
      final data = response.data;

      if (data['success'] == true) {
        final list = (data['data']['notifications'] as List? ?? [])
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        state = state.copyWith(
          isLoading: false,
          notifications: list,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: data['message'] ?? '알림을 불러올 수 없습니다.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '알림을 불러올 수 없습니다.',
      );
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final response =
          await ApiClient.instance.dio.get('/notifications/unread-count');
      final data = response.data;

      if (data['success'] == true) {
        state = state.copyWith(
          unreadCount: data['data']['unreadCount'] ?? 0,
        );
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Error loading unread count: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await ApiClient.instance.dio.put('/notifications/$id/read');

      final updated = state.notifications.map((n) {
        if (n.id == id && !n.isRead) {
          return NotificationModel(
            id: n.id,
            type: n.type,
            title: n.title,
            body: n.body,
            isRead: true,
            readAt: DateTime.now(),
            data: n.data,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      final newUnread = updated.where((n) => !n.isRead).length;
      state = state.copyWith(notifications: updated, unreadCount: newUnread);
    } catch (e) {
      debugPrint('[NotificationProvider] Error marking as read: $e');
      state = state.copyWith(error: '알림 읽음 처리에 실패했습니다.');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiClient.instance.dio.put('/notifications/read-all');

      final updated = state.notifications
          .map((n) => NotificationModel(
                id: n.id,
                type: n.type,
                title: n.title,
                body: n.body,
                isRead: true,
                readAt: DateTime.now(),
                data: n.data,
                createdAt: n.createdAt,
              ))
          .toList();

      state = state.copyWith(notifications: updated, unreadCount: 0);
    } catch (e) {
      debugPrint('[NotificationProvider] Error marking all as read: $e');
      state = state.copyWith(error: '알림 읽음 처리에 실패했습니다.');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await ApiClient.instance.dio.delete('/notifications/$id');

      final updated =
          state.notifications.where((n) => n.id != id).toList();
      final newUnread = updated.where((n) => !n.isRead).length;
      state = state.copyWith(notifications: updated, unreadCount: newUnread);
    } catch (e) {
      debugPrint('[NotificationProvider] Error deleting notification: $e');
      state = state.copyWith(error: '알림 삭제에 실패했습니다.');
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
