import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/user_type_provider.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../shared/widgets/ui/ui.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userType = ref.watch(userTypeProvider);
    final userTypeLabel = switch (userType) {
      UserType.reviewer => '리뷰어',
      UserType.consumer => '소비자',
      UserType.business => '업체',
    };

    return AppScreen(
      title: '설정',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          AppSection(
            title: '계정',
            topGap: 0,
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppListRow(
                    icon: Icons.person_outline,
                    title: '프로필 수정',
                    onTap: () => context.push('/edit-profile'),
                  ),
                  const AppDivider(),
                  AppListRow(
                    icon: Icons.lock_outline,
                    title: '비밀번호 변경',
                    onTap: () => context.push('/forgot-password'),
                  ),
                  const AppDivider(),
                  AppListRow(
                    icon: Icons.notifications_outlined,
                    title: '알림 설정',
                    onTap: () => context.push('/notifications-settings'),
                  ),
                  const AppDivider(),
                  AppListRow(
                    icon: Icons.swap_horiz_rounded,
                    title: '사용자 유형 변경',
                    subtitle: '현재: $userTypeLabel',
                    onTap: () => context.push('/select-user-type'),
                  ),
                ],
              ),
            ),
          ),
          AppSection(
            title: '정보',
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppListRow(
                    icon: Icons.accessibility_new_rounded,
                    title: '접근성',
                    onTap: () => context.push('/accessibility'),
                  ),
                  const AppDivider(),
                  AppListRow(
                    icon: Icons.description_outlined,
                    title: '이용약관',
                    onTap: () => context.push('/terms'),
                  ),
                  const AppDivider(),
                  AppListRow(
                    icon: Icons.privacy_tip_outlined,
                    title: '개인정보처리방침',
                    onTap: () => context.push('/privacy'),
                  ),
                  const AppDivider(),
                  AppListRow(
                    icon: Icons.info_outline,
                    title: '앱 정보',
                    onTap: () => context.push('/about'),
                  ),
                ],
              ),
            ),
          ),
          AppSection(
            title: '계정 정리',
            child: AppCard(
              style: AppCardStyle.outlined,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppListRow(
                    icon: Icons.logout_rounded,
                    title: '로그아웃',
                    onTap: () => _logout(context),
                  ),
                  const AppDivider(),
                  AppListRow(
                    icon: Icons.person_remove_outlined,
                    title: '회원 탈퇴',
                    subtitle: '모든 데이터가 삭제되며 되돌릴 수 없습니다',
                    destructive: true,
                    onTap: () => _deleteAccount(context),
                  ),
                ],
              ),
            ),
          ),
          const AppBottomSpacer.plain(),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showAppConfirm(
      context: context,
      title: '로그아웃할까요?',
      message: '다시 로그인하면 그대로 이어서 쓸 수 있습니다.',
      confirmLabel: '로그아웃',
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !context.mounted) return;

    const storage = FlutterSecureStorage();
    await storage.delete(key: 'auth_token');
    if (context.mounted) context.go('/login');
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showAppConfirm(
      context: context,
      title: '정말 탈퇴할까요?',
      message: '작성한 리뷰와 감찰 이력, 등급이 모두 사라집니다. '
          '되돌릴 수 없습니다.',
      confirmLabel: '탈퇴하기',
      destructive: true,
      icon: Icons.person_remove_outlined,
    );
    if (!confirmed || !context.mounted) return;

    try {
      // 백엔드 계정 삭제. 진행 중 미션/미정산이 있으면 400 + 안내 메시지.
      await ApiClient().delete('/users/me');

      // FCM 토큰 해제 + 로컬 인증정보 삭제
      await FcmService().removeTokenFromBackend();
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'auth_token');

      if (context.mounted) context.go('/login');
    } catch (e) {
      if (!context.mounted) return;
      AppToast.error(
        context,
        ApiClient.extractErrorMessage(e) ??
            '회원 탈퇴에 실패했습니다. 진행 중인 미션이나 미정산 내역이 없는지 확인해주세요.',
      );
    }
  }
}
