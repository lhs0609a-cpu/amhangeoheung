import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';
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
    final hasUnread = state.notifications.any((n) => !n.isRead);

    return AppScreen(
      title: '알림',
      actions: [
        if (hasUnread)
          AppButton.ghost(
            label: '모두 읽음',
            size: AppButtonSize.small,
            onPressed: () =>
                ref.read(notificationProvider.notifier).markAllAsRead(),
          ),
      ],
      onRefresh: () =>
          ref.read(notificationProvider.notifier).loadNotifications(),
      applyGutter: false,
      child: _buildBody(state),
    );
  }

  Widget _buildBody(NotificationState state) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 120),
        child: Center(
          child: CircularProgressIndicator(color: HwahaeColors.primary),
        ),
      );
    }

    if (state.error != null) {
      return AppErrorState.fromMessage(
        state.error!,
        onRetry: () =>
            ref.read(notificationProvider.notifier).loadNotifications(),
      );
    }

    if (state.notifications.isEmpty) {
      return const AppEmptyState(
        icon: Icons.notifications_none_rounded,
        title: '조용하네',
        message: '새 소식이 생기면 여기로 알려줄게',
        showMascot: true,
      );
    }

    return Column(
      children: [
        for (var i = 0; i < state.notifications.length; i++) ...[
          if (i > 0) const AppDivider(indent: 68),
          _NotificationTile(
            notification: state.notifications[i],
            onTap: () {
              final n = state.notifications[i];
              if (!n.isRead) {
                ref.read(notificationProvider.notifier).markAsRead(n.id);
              }
            },
            onDismissed: () => ref
                .read(notificationProvider.notifier)
                .deleteNotification(state.notifications[i].id),
          ),
        ],
      ],
    );
  }
}

/// 알림 종류를 사람이 읽는 묶음으로 되돌린다.
///
/// 예전에는 `type` 을 'mission' / 'review' 같은 짧은 이름과 비교했는데,
/// 서버가 보내는 값은 `mission_new`, `review_published` 처럼 구체적인
/// 타입이다. 그래서 거의 모든 알림이 기본 아이콘(종)으로 떨어졌다.
/// 접두사로 묶으면 새 타입이 추가돼도 알아서 분류된다.
enum _Kind {
  mission(Icons.flag_rounded, HwahaeColors.primaryDark),
  review(Icons.rate_review_rounded, HwahaeColors.accent),
  settlement(Icons.account_balance_wallet_rounded, HwahaeColors.warning),

  /// 경고류. 자격 정지·품질·담합처럼 조치가 필요한 것들.
  warning(Icons.gpp_maybe_rounded, HwahaeColors.secondary),
  system(Icons.info_outline_rounded, HwahaeColors.info);

  const _Kind(this.icon, this.color);
  final IconData icon;
  final Color color;

  static _Kind of(String type) {
    if (type.contains('warning') ||
        type.contains('suspended') ||
        type.contains('blocked') ||
        type.contains('failed')) {
      return _Kind.warning;
    }
    if (type.startsWith('mission') ||
        type.startsWith('hidden_mission') ||
        type.startsWith('season') ||
        type.startsWith('tutorial') ||
        type.startsWith('detection_test') ||
        type.startsWith('review_request')) {
      return _Kind.mission;
    }
    if (type.startsWith('review') || type.startsWith('dispute')) {
      return _Kind.review;
    }
    if (type.startsWith('settlement')) return _Kind.settlement;
    if (type.startsWith('certification') ||
        type.startsWith('recertification')) {
      return _Kind.warning;
    }
    return _Kind.system;
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

  @override
  Widget build(BuildContext context) {
    final kind = _Kind.of(notification.type);
    final unread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        color: HwahaeColors.errorStrong,
        child: const Icon(
          Icons.delete_outline_rounded,
          // errorStrong 위의 크림색은 6.26:1. 흰색을 쓰면 안 된다.
          color: HwahaeColors.textOnDark,
        ),
      ),
      onDismissed: (_) => onDismissed(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: unread
              ? HwahaeColors.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kind.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(kind.icon, size: 20, color: kind.color),
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
                            unread ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: HwahaeTypography.bodySmall.copyWith(
                          color: HwahaeColors.textSecondary,
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
              if (unread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  decoration: const BoxDecoration(
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
