import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/company_info.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  /// 카카오톡 상담 채널.
  static const String _kakaoChannel = 'https://pf.kakao.com/amhangeoheung';

  @override
  Widget build(BuildContext context) {
    // 빌드타임에 주입되지 않았으면 전화 버튼을 아예 내린다. placeholder 로
    // 전화를 걸면 아무 데도 연결되지 않는데, 사용자는 연결을 시도했다고
    // 믿고 기다린다.
    final phone = CompanyInfo.customerServicePhone;
    final hasPhone = !phone.contains('[');

    return AppScreen(
      title: '고객센터',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppMascot.sato(size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '암행어흥 고객센터',
                            style: HwahaeTypography.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '평일 09:00 - 18:00',
                            style: HwahaeTypography.captionMedium.copyWith(
                              color: HwahaeColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (hasPhone) ...[
                      Expanded(
                        child: AppButton.tonal(
                          label: '전화 상담',
                          icon: Icons.phone_rounded,
                          onPressed: () =>
                              _launch(context, Uri.parse('tel:$phone')),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: AppButton.outline(
                        label: '카카오톡',
                        icon: Icons.chat_bubble_outline_rounded,
                        onPressed: () => _launch(
                          context,
                          Uri.parse(_kakaoChannel),
                          external: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSection(
            title: '자주 묻는 질문',
            child: Column(
              children: [
                for (final faq in _faqs) ...[
                  _FaqItem(faq: faq),
                  const SizedBox(height: AppLayout.cardGap),
                ],
              ],
            ),
          ),
          AppSection(
            title: '1:1 문의',
            subtitle: '이메일로 받습니다',
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppListRow(
                    icon: Icons.email_outlined,
                    iconColor: HwahaeColors.onPrimaryContainer,
                    title: '일반 문의',
                    subtitle: CompanyInfo.privacyEmail,
                    onTap: () => _mail(context, '[문의] '),
                  ),
                  const AppDivider(indent: 56),
                  AppListRow(
                    icon: Icons.report_problem_outlined,
                    iconColor: HwahaeColors.secondary,
                    title: '신고하기',
                    subtitle: '부적절한 콘텐츠 또는 이용자 신고',
                    // 예전에는 빈 콜백이라 눌러도 아무 일이 없었다.
                    // 제목만 채운 메일로 보내면 적어도 접수는 된다.
                    onTap: () => _mail(
                      context,
                      '[신고] ',
                      body: '신고 대상(업체명·리뷰어 닉네임·리뷰 링크):\n\n'
                          '신고 사유:\n\n',
                    ),
                  ),
                  const AppDivider(indent: 56),
                  AppListRow(
                    icon: Icons.feedback_outlined,
                    iconColor: HwahaeColors.accent,
                    title: '서비스 개선 제안',
                    subtitle: '암행어흥을 더 좋게 만들어주세요',
                    onTap: () => _mail(
                      context,
                      '[제안] ',
                      body: '어느 화면에서 무엇이 불편했는지 적어주시면 '
                          '그 화면부터 고칩니다.\n\n',
                    ),
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

  Future<void> _mail(
    BuildContext context,
    String subjectPrefix, {
    String body = '',
  }) {
    final uri = Uri(
      scheme: 'mailto',
      path: CompanyInfo.privacyEmail,
      query: Uri(queryParameters: {
        'subject': '$subjectPrefix암행어흥 ${CompanyInfo.appVersion}',
        if (body.isNotEmpty) 'body': body,
      }).query,
    );
    return _launch(context, uri);
  }

  /// 링크를 연다. 열 수 없으면 조용히 넘어가지 않고 알린다.
  ///
  /// 예전에는 `canLaunchUrl` 이 false 면 아무 일도 하지 않았다. 사용자
  /// 입장에서는 버튼이 고장 난 것과 구분되지 않는다.
  Future<void> _launch(
    BuildContext context,
    Uri uri, {
    bool external = false,
  }) async {
    final opened = await canLaunchUrl(uri) &&
        await launchUrl(
          uri,
          mode: external
              ? LaunchMode.externalApplication
              : LaunchMode.platformDefault,
        );

    if (!opened && context.mounted) {
      AppToast.error(context, '연결할 수 있는 앱이 없습니다: ${uri.scheme}');
    }
  }
}

class _Faq {
  const _Faq(this.question, this.answer);
  final String question;
  final String answer;
}

const _faqs = <_Faq>[
  _Faq(
    '미션은 어떻게 신청하나요?',
    '홈 화면 또는 미션 탭에서 원하는 미션을 선택한 후 "미션 신청" 버튼을 누르면 '
        '됩니다. 배정되면 업체 정보가 공개되며, 3일 이내에 방문해야 합니다.',
  ),
  _Faq(
    '정산은 언제 되나요?',
    '리뷰가 승인되면 정산 대기 금액에 추가됩니다. 정산 신청 후 영업일 기준 '
        '3~5일 이내에 등록된 계좌로 입금됩니다.',
  ),
  _Faq(
    '리뷰가 반려되면 어떻게 되나요?',
    '반려 사유를 확인하고 수정하여 다시 제출할 수 있습니다. 수정 기한 내에 '
        '제출하지 않으면 미션이 취소됩니다.',
  ),
  _Faq(
    '미션을 취소할 수 있나요?',
    '배정 후 방문 전에는 취소가 가능합니다. 다만 잦은 취소는 신뢰도에 영향을 '
        '줄 수 있습니다.',
  ),
  _Faq(
    '등급은 어떻게 올릴 수 있나요?',
    '미션 완료 횟수, 리뷰 품질, 신뢰도 점수에 따라 등급이 결정됩니다. 양질의 '
        '리뷰를 꾸준히 작성하면 등급이 올라갑니다.',
  ),
  _Faq(
    '업체가 돈을 내면 리뷰를 지울 수 있나요?',
    '없습니다. 구독은 감찰을 요청하고 결과를 먼저 보는 권리를 살 뿐이고, '
        '리뷰 내용과 공개 여부는 바꿀 수 없습니다. 사실과 다른 부분이 있으면 '
        '이의를 제기할 수 있고, 그 처리 결과도 함께 공개됩니다.',
  ),
];

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.faq});

  final _Faq faq;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      style: AppCardStyle.outlined,
      padding: EdgeInsets.zero,
      child: Theme(
        // ExpansionTile 기본 구분선을 지운다. 카드 테두리와 겹쳐 두 줄이 된다.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: HwahaeColors.textSecondary,
          collapsedIconColor: HwahaeColors.textTertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          ),
          title: Text(faq.question, style: HwahaeTypography.titleSmall),
          children: [
            Text(
              faq.answer,
              style: HwahaeTypography.bodySmall.copyWith(
                color: HwahaeColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
