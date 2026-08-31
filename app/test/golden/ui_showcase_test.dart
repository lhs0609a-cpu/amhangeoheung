import 'dart:io';

import 'package:amhangeoheung_app/core/theme/hwahae_colors.dart';
import 'package:amhangeoheung_app/core/theme/hwahae_theme.dart';
import 'package:amhangeoheung_app/core/theme/hwahae_typography.dart';
import 'package:amhangeoheung_app/shared/widgets/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 화면을 실제로 렌더링해 PNG 로 떨어뜨린다.
///
/// 대비는 숫자로 검사할 수 있지만(contrast_test.dart) "예쁜지"는 계산으로
/// 알 수 없다. 이 테스트는 통과/실패를 다투는 것이 목적이 아니라
/// `flutter test --update-goldens test/golden` 으로 그림을 만들어
/// 사람이(그리고 도구가) 눈으로 확인하기 위한 것이다.
///
/// 테스트 환경에는 시스템 한글 서체가 없어 본문이 두부(tofu)로 나온다.
/// 번들된 Jua 를 기본 서체로 깔아 한글이 보이게 한다 — 운영과 본문 서체가
/// 다르므로 자간·줄바꿈은 참고만 하고, 색·간격·구성만 본다.
Future<void> _loadJua() async {
  final bytes = await rootBundle.load('assets/fonts/Jua-Regular.ttf');
  final loader = FontLoader('Jua')..addFont(Future.value(bytes));
  await loader.load();

  // 본문 서체(null → 테스트 기본 Roboto)에도 한글이 없어 두부가 된다.
  // 테스트 안에서만 Jua 를 기본값으로 깐다.
  //
  // 부작용: Roboto 를 덮어쓰므로 Jua 에 없는 기호(·, — 등)가 골든에서 두부로
  // 찍힌다. 운영에서는 HwahaeTypography.displayFallback 이 시스템 서체로
  // 흘려보내므로 정상이다 — 그 배선은 typography_test.dart 가 검사한다.
  final fallback = FontLoader('Roboto')..addFont(Future.value(bytes));
  await fallback.load();
}

Future<void> _shoot(
  WidgetTester tester,
  String name,
  Widget child, {
  Size size = const Size(390, 844),
  Color background = HwahaeColors.background,
}) async {
  // physicalSize 는 물리 픽셀이다. dpr 2 로 찍으려면 논리 크기의 두 배를 준다.
  // (예전에 논리 크기를 그대로 넣어 화면이 195pt 로 잡히는 바람에 칩이
  //  가로를 꽉 채우고 인장이 넘쳤다.)
  const double dpr = 2.0;
  tester.view.physicalSize = Size(size.width * dpr, size.height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: HwahaeTheme.lightTheme,
      // Material 조상이 없으면 Flutter 가 모든 글자에 노란 밑줄 경고를 그린다.
      home: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle(const Duration(seconds: 1));

  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('shots/$name.png'),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadJua();
    Directory('test/golden/shots').createSync(recursive: true);
  });

  testWidgets('01 버튼 — 모든 변형', (tester) async {
    await _shoot(
      tester,
      '01_buttons',
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            AppButton(label: '감찰 리포트 보기', onPressed: () {}),
            const SizedBox(height: 12),
            AppButton.secondary(label: '현장 도착 · 체크인', onPressed: () {}),
            const SizedBox(height: 12),
            AppButton.tonal(label: '더보기', onPressed: () {}),
            const SizedBox(height: 12),
            AppButton.outline(label: '취소', onPressed: () {}),
            const SizedBox(height: 12),
            AppButton.danger(label: '감찰 취소', onPressed: () {}),
            const SizedBox(height: 12),
            AppButton.ghost(label: '건너뛰기', onPressed: () {}),
            const SizedBox(height: 20),
            AppButton(label: '비활성', onPressed: null),
          ],
        ),
      ),
    );
  });

  testWidgets('02 칩과 배지와 인장', (tester) async {
    await _shoot(
      tester,
      '02_chips_seal',
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppChip(label: '전체', selected: true, onTap: () {}),
                AppChip(label: '감찰됨', onTap: () {}),
                AppChip(label: '미감찰', onTap: () {}),
                AppChip(
                  label: '히든',
                  selected: true,
                  accent: HwahaeColors.missionHidden,
                  onTap: () {},
                ),
                AppChip(
                  label: '시즌',
                  selected: true,
                  accent: HwahaeColors.missionSeason,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                AppBadge(label: '고침', color: HwahaeColors.accent, filled: true),
                AppBadge(
                    label: '아직', color: HwahaeColors.secondary, filled: true),
                AppBadge(
                    label: '마스터', color: HwahaeColors.gradeGold, filled: true),
                AppBadge(
                    label: '시니어', color: HwahaeColors.gradeSilver, filled: true),
                AppBadge(label: '루키', color: HwahaeColors.gradeRookie, filled: true),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: const [
                SealBadge(count: 1),
                SizedBox(width: 16),
                SealBadge(count: 2),
                SizedBox(width: 16),
                SealBadge(count: 12, size: 58),
                SizedBox(width: 16),
                SealBadge(count: 0),
              ],
            ),
          ],
        ),
      ),
    );
  });

  testWidgets('03 빈 화면 — 어흥이', (tester) async {
    await _shoot(
      tester,
      '03_empty_mascot',
      const Center(
        child: AppEmptyState(
          icon: Icons.flag_outlined,
          showMascot: true,
          title: '어흥, 지금은 갈 곳이 없네',
          message: '새 감찰이 열리면 바로 알려줄게',
        ),
      ),
    );
  });

  testWidgets('04 어흥이 말풍선과 사또', (tester) async {
    await _shoot(
      tester,
      '04_mascot_messages',
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const MascotMessage(
              message: '어흥, 여긴 아직 안 가봤는데',
              detail: '감찰 요청이 12건 쌓였어',
            ),
            const SizedBox(height: 12),
            const MascotMessage(
              kind: MascotKind.sato,
              dark: true,
              message: '신분을 밝히면 안 되네',
              detail: '들키면 보수가 지급되지 않아',
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                AppMascot.eoheung(size: 96),
                AppMascot.sato(size: 96),
              ],
            ),
          ],
        ),
      ),
    );
  });

  testWidgets('05 신뢰 카드 — 지적과 개선', (tester) async {
    Widget row(String title, String detail, bool fixed) {
      return Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          border: Border.all(
            color: fixed ? HwahaeColors.border : HwahaeColors.secondary,
            width: 2,
          ),
          boxShadow: AppElevation.sticker(
            3,
            color: fixed ? HwahaeColors.stickerShadow : HwahaeColors.secondaryContainer,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: fixed
                    ? HwahaeColors.accentContainer
                    : HwahaeColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                fixed ? Icons.check_rounded : Icons.priority_high_rounded,
                size: 16,
                color: fixed
                    ? HwahaeColors.onAccentContainer
                    : HwahaeColors.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: HwahaeTypography.titleSmall),
                  const SizedBox(height: 5),
                  Text(detail,
                      style: HwahaeTypography.captionMedium
                          .copyWith(color: HwahaeColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppBadge(
              label: fixed ? '고침' : '아직',
              color: fixed ? HwahaeColors.accent : HwahaeColors.secondary,
              filled: true,
            ),
          ],
        ),
      );
    }

    await _shoot(
      tester,
      '05_trust_card',
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('일식 · 서울 강남구',
                          style: HwahaeTypography.captionMedium
                              .copyWith(color: HwahaeColors.textTertiary)),
                      const SizedBox(height: 8),
                      Text('스시무라', style: HwahaeTypography.displaySmall),
                    ],
                  ),
                ),
                const SealBadge(count: 2),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: HwahaeColors.surface,
                borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
                border: Border.all(color: HwahaeColors.border, width: 2),
                boxShadow: AppElevation.sticker(3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('4.2', style: HwahaeTypography.displayMedium),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('감찰 평점\n일반 후기 아님',
                            style: HwahaeTypography.captionMedium
                                .copyWith(color: HwahaeColors.textTertiary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const AppProgressBar(value: 0.67),
                  const SizedBox(height: 12),
                  Text(
                    '무작위로 뽑힌 감찰관이 2번 다녀갔고, 지적된 3건 중 2건을 고쳤어요.',
                    style: HwahaeTypography.bodyMedium
                        .copyWith(color: HwahaeColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            row('웨이팅 안내가 없음', '대기 알림 도입 → 2차에서 확인', true),
            row('화장실 청결 상태', '청소 주기 2시간으로 단축', true),
            row('점심 시간대 응대 지연', '2차에서도 똑같이 지적됨', false),
          ],
        ),
      ),
    );
  });

  testWidgets('06 감찰 도메인 — 지적·이력·블라인드 미션', (tester) async {
    await _shoot(
      tester,
      '06_inspection',
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const FindingCard(
              finding: InspectionFinding(
                title: '웨이팅 안내가 없음',
                detail: '대기 알림 도입 → 2차에서 확인',
                fixed: true,
              ),
            ),
            const SizedBox(height: 9),
            const FindingCard(
              finding: InspectionFinding(
                title: '점심 시간대 응대 지연',
                detail: '2차에서도 똑같이 지적됨',
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HwahaeColors.surface,
                borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                border: Border.all(color: HwahaeColors.border, width: 2),
                boxShadow: AppElevation.sticker(3),
              ),
              child: const InspectionTimeline(
                steps: [
                  InspectionStep(
                    kind: InspectionStepKind.finding,
                    label: '1차 감찰',
                    date: '2026.03.12',
                    detail: '지적 3건 — 대기 안내, 화장실 청결, 응대 지연',
                  ),
                  InspectionStep(
                    kind: InspectionStepKind.promise,
                    label: '개선 약속',
                    date: '2026.03.15',
                    detail: '대기 알림 도입, 청소 주기 2시간',
                  ),
                  InspectionStep(
                    kind: InspectionStepKind.verified,
                    label: '2차 감찰',
                    date: '2026.06.20',
                    detail: '2건 개선 확인 · 1건 미개선',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const BlindMissionCard(
              category: '일식',
              region: '강남구',
              schedule: '점심 방문 · 최소 체류 40분',
              fee: 54000,
              applicants: 6,
              deadline: '마감까지 2일',
            ),
            const SizedBox(height: 10),
            const BlindMissionCard(
              category: '한식',
              region: '강남구',
              schedule: '저녁 방문 · 최소 체류 50분',
              fee: 61000,
              blockedReason: '6개월 내 감찰 이력이 있어 지원할 수 없습니다',
            ),
          ],
        ),
      ),
    );
  });

  testWidgets('07 현장 체류 타이머', (tester) async {
    await _shoot(
      tester,
      '07_stay_timer',
      background: HwahaeColors.textPrimary,
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const StayTimerRing(
              elapsed: Duration(minutes: 31, seconds: 4),
              required: Duration(minutes: 40),
            ),
            const SizedBox(height: 40),
            const StayTimerRing(
              elapsed: Duration(minutes: 42),
              required: Duration(minutes: 40),
              size: 160,
            ),
          ],
        ),
      ),
    );
  });
}
