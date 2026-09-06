import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('알림', style: HwahaeTypography.titleMedium),
        actions: [
          if (state.notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
              },
              child: Text(
                '모두 읽음',
                style: HwahaeTypography.bodySmall.copyWith(
                  color: HwahaeColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(NotificationState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: HwahaeColors.primary));
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: HwahaeColors.textTertiary),
            const SizedBox(height: 16),
            Text(state.error!, style: HwahaeTypography.bodyMedium),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                ref.read(notificationProvider.notifier).loadNotifications();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: HwahaeColors.textTertiary),
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
      onRefresh: () async {
        await ref.read(notificationProvider.notifier).loadNotifications();
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.notifications.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: HwahaeColors.border,
        ),
        itemBuilder: (context, index) {
          final notification = state.notifications[index];
          return _NotificationTile(
            notification: notification,
            onTap: () {
              if (!notification.isRead) {
                ref
                    .read(notificationProvider.notifier)
                    .markAsRead(notification.id);
              }
            },
            onDismissed: () {
              ref
                  .read(notificationProvider.notifier)
                  .deleteNotification(notification.id);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismissed,
  });

  IconData _iconForType(String type) {
    switch (type) {
      case 'mission':
        return Icons.assignment;
      case 'review':
        return Icons.rate_review;
      case 'settlement':
        return Icons.account_balance_wallet;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'mission':
        return HwahaeColors.primary;
      case 'review':
        return HwahaeColors.success;
      case 'settlement':
        return HwahaeColors.warning;
      case 'system':
        return HwahaeColors.info;
      default:
        return HwahaeColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: HwahaeColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismissed(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notification.isRead
              ? HwahaeColors.surface
              : HwahaeColors.primary.withValues(alpha: 0.04),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _colorForType(notification.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconForType(notification.type),
                  size: 20,
                  color: _colorForType(notification.type),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: HwahaeTypography.bodyMedium.copyWith(
                        fontWeight:
                            notification.isRead ? FontWeight.w400 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: HwahaeTypography.bodySmall.copyWith(
                        color: HwahaeColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.timeAgo,
                      style: HwahaeTypography.labelSmall.copyWith(
                        color: HwahaeColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  decoration: BoxDecoration(
                    color: HwahaeColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
