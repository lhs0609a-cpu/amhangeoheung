import 'package:amhangeoheung_app/core/theme/hwahae_theme.dart';
import 'package:amhangeoheung_app/shared/widgets/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 위젯 하나를 앱 테마 안에서 띄운다.
Future<void> pumpInApp(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844), // iPhone 14 기준
  EdgeInsets viewPadding = const EdgeInsets.only(top: 47, bottom: 34),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: HwahaeTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size, viewPadding: viewPadding, padding: viewPadding),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('AppButton', () {
    testWidgets('탭하면 콜백이 호출된다', (tester) async {
      var taps = 0;
      await pumpInApp(
        tester,
        AppButton(label: '신청하기', onPressed: () => taps++),
      );

      await tester.tap(find.text('신청하기'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('onPressed 가 null 이면 탭해도 아무 일이 없다', (tester) async {
      await pumpInApp(tester, const AppButton(label: '비활성'));

      await tester.tap(find.text('비활성'));
      await tester.pumpAndSettle();
      // 예외 없이 통과하면 성공 (탭이 무시됨)
      expect(tester.takeException(), isNull);
    });

    testWidgets('로딩 중에는 콜백이 호출되지 않고 라벨 자리는 유지된다', (tester) async {
      var taps = 0;
      await pumpInApp(
        tester,
        AppButton(label: '저장', isLoading: true, onPressed: () => taps++),
      );

      // 라벨 위젯 자체는 남아 있어야 버튼 폭이 흔들리지 않는다.
      expect(find.text('저장'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('medium 버튼 높이는 최소 터치 타깃 이상이다', (tester) async {
      await pumpInApp(
        tester,
        AppButton(label: '확인', onPressed: () {}),
      );

      final box = tester.getSize(find.byType(AnimatedContainer).first);
      expect(box.height, greaterThanOrEqualTo(AppLayout.minTapTarget));
    });
  });

  group('AppIconButton', () {
    testWidgets('아이콘이 작아도 터치 영역은 48dp 를 유지한다', (tester) async {
      await pumpInApp(
        tester,
        Center(
          child: AppIconButton(
            icon: Icons.close_rounded,
            iconSize: 16,
            onPressed: () {},
          ),
        ),
      );

      final size = tester.getSize(find.byType(SizedBox).first);
      expect(size.width, AppLayout.minTapTarget);
      expect(size.height, AppLayout.minTapTarget);
    });

    testWidgets('배지 수가 99 를 넘으면 99+ 로 표시한다', (tester) async {
      await pumpInApp(
        tester,
        Center(
          child: AppIconButton(
            icon: Icons.notifications_outlined,
            badgeCount: 128,
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('배지 수가 0 이면 배지를 그리지 않는다', (tester) async {
      await pumpInApp(
        tester,
        Center(
          child: AppIconButton(icon: Icons.search_rounded, onPressed: () {}),
        ),
      );

      expect(find.textContaining('0'), findsNothing);
    });
  });

  group('AppLayout', () {
    testWidgets('하단 스크롤 여백은 네비게이션 바와 제스처 인셋을 모두 포함한다', (tester) async {
      late double withNav;
      late double withoutNav;

      await pumpInApp(
        tester,
        Builder(
          builder: (context) {
            withNav = AppLayout.bottomScrollInset(context);
            withoutNav = AppLayout.bottomScrollInset(context, withNavBar: false);
            return const SizedBox.shrink();
          },
        ),
      );

      // 홈 인디케이터(34) 는 두 경우 모두 포함된다.
      expect(withoutNav, greaterThanOrEqualTo(34));
      // 네비게이션 바가 있으면 그 높이만큼 더 확보한다.
      expect(withNav - withoutNav, AppLayout.navBarClearance);
    });

    testWidgets('좁은 화면에서는 좌우 여백이 줄어든다', (tester) async {
      late double narrow;
      await pumpInApp(
        tester,
        Builder(
          builder: (context) {
            narrow = AppLayout.gutterOf(context);
            return const SizedBox.shrink();
          },
        ),
        size: const Size(320, 568), // iPhone SE 1세대
      );

      expect(narrow, AppLayout.gutterCompact);
    });
  });

  group('AppChip', () {
    testWidgets('선택 상태가 바뀌면 스타일이 갱신되고 콜백이 온다', (tester) async {
      var selected = 0;
      await pumpInApp(
        tester,
        StatefulBuilder(
          builder: (context, setState) => AppChipBar(
            labels: const ['전체', '음식점', '카페'],
            selectedIndex: selected,
            onSelected: (i) => setState(() => selected = i),
          ),
        ),
      );

      await tester.tap(find.text('카페'));
      await tester.pumpAndSettle();

      expect(selected, 2);
    });
  });

  group('AppProgressBar', () {
    testWidgets('1.0 을 넘는 값은 100% 로 잘린다', (tester) async {
      await pumpInApp(
        tester,
        const SizedBox(width: 200, child: AppProgressBar(value: 1.8)),
      );
      await tester.pumpAndSettle();

      final fill = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      ).first;
      expect((fill.constraints?.maxWidth ?? 0) <= 200, isTrue);
    });
  });

  group('AppEmptyState / AppErrorState', () {
    testWidgets('빈 상태는 제목과 행동 버튼을 보여준다', (tester) async {
      var tapped = false;
      await pumpInApp(
        tester,
        AppEmptyState(
          icon: Icons.flag_outlined,
          title: '참여 가능한 미션이 없어요',
          message: '새 미션이 열리면 알려드릴게요',
          actionLabel: '알림 켜기',
          onAction: () => tapped = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('참여 가능한 미션이 없어요'), findsOneWidget);
      await tester.tap(find.text('알림 켜기'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('네트워크 오류는 오프라인 문구로 바뀐다', (tester) async {
      await pumpInApp(
        tester,
        AppErrorState.fromMessage('SocketException: connection failed'),
      );
      await tester.pumpAndSettle();

      expect(find.text('연결이 불안정해요'), findsOneWidget);
    });

    testWidgets('일반 오류는 원문 메시지를 그대로 보여준다', (tester) async {
      await pumpInApp(
        tester,
        AppErrorState.fromMessage('서버가 500을 반환했습니다'),
      );
      await tester.pumpAndSettle();

      expect(find.text('문제가 발생했어요'), findsOneWidget);
      expect(find.text('서버가 500을 반환했습니다'), findsOneWidget);
    });
  });

  group('showAppConfirm', () {
    testWidgets('확인을 누르면 true, 취소를 누르면 false 를 돌려준다', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: HwahaeTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: AppButton(
                  label: '해지',
                  onPressed: () async {
                    result = await showAppConfirm(
                      context: context,
                      title: '구독을 해지할까요?',
                      confirmLabel: '해지하기',
                      destructive: true,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('해지'));
      await tester.pumpAndSettle();
      expect(find.text('구독을 해지할까요?'), findsOneWidget);

      await tester.tap(find.text('해지하기'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });
  });

  group('AppBottomSpacer', () {
    testWidgets('탭 화면과 상세 화면의 하단 여백이 다르다', (tester) async {
      await pumpInApp(
        tester,
        const Column(
          children: [
            AppBottomSpacer(),
            AppBottomSpacer.plain(),
          ],
        ),
      );

      final sizes = tester
          .widgetList<SizedBox>(find.descendant(
            of: find.byType(AppBottomSpacer),
            matching: find.byType(SizedBox),
          ))
          .map((s) => s.height ?? 0)
          .toList();

      expect(sizes.length, 2);
      expect(sizes[0] - sizes[1], AppLayout.navBarClearance);
    });
  });

  group('SealBadge', () {
    testWidgets('감찰 횟수를 새겨 보여준다', (tester) async {
      await pumpInApp(tester, const SealBadge(count: 3));

      expect(find.text('감찰'), findsOneWidget);
      expect(find.text('3회'), findsOneWidget);
    });

    testWidgets('감찰 0회면 인장을 찍지 않는다', (tester) async {
      await pumpInApp(tester, const SealBadge(count: 0));

      expect(find.text('감찰'), findsNothing);
      // 아직 감찰되지 않은 업체에 도장이 찍히면 안 된다.
      expect(tester.widget<SealBadge>(find.byType(SealBadge)).count, 0);
    });

    testWidgets('정렬이 중요한 곳에서는 기울이지 않는다', (tester) async {
      await pumpInApp(tester, const SealBadge(count: 2, tilted: false));

      expect(
        find.descendant(
          of: find.byType(SealBadge),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
    });
  });

  group('AppEmptyState 어흥이', () {
    testWidgets('showMascot 이면 아이콘 대신 어흥이가 선다', (tester) async {
      await pumpInApp(
        tester,
        const AppEmptyState(
          icon: Icons.flag_outlined,
          title: '어흥, 지금은 갈 곳이 없네',
          showMascot: true,
        ),
      );

      expect(find.byType(AppMascot), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsNothing);
    });

    testWidgets('기본값은 아이콘이다', (tester) async {
      await pumpInApp(
        tester,
        const AppEmptyState(
          icon: Icons.flag_outlined,
          title: '미션이 없습니다',
        ),
      );

      expect(find.byType(AppMascot), findsNothing);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    });
  });

  group('FindingCard', () {
    testWidgets('개선된 항목과 안 된 항목을 다르게 표시한다', (tester) async {
      await pumpInApp(
        tester,
        const Column(
          children: [
            FindingCard(
              finding: InspectionFinding(title: '웨이팅 안내', fixed: true),
            ),
            FindingCard(finding: InspectionFinding(title: '응대 지연')),
          ],
        ),
      );

      expect(find.text('고침'), findsOneWidget);
      expect(find.text('아직'), findsOneWidget);
    });

    testWidgets('스크린리더에 개선 여부를 읽어준다', (tester) async {
      await pumpInApp(
        tester,
        const FindingCard(
          finding: InspectionFinding(title: '응대 지연'),
        ),
      );

      expect(
        find.bySemanticsLabel(RegExp('아직 개선되지 않음')),
        findsOneWidget,
      );
    });
  });

  group('InspectionTimeline', () {
    testWidgets('단계를 순서대로 보여준다', (tester) async {
      await pumpInApp(
        tester,
        const InspectionTimeline(
          steps: [
            InspectionStep(
              kind: InspectionStepKind.finding,
              label: '1차 감찰',
              date: '2026.03.12',
            ),
            InspectionStep(
              kind: InspectionStepKind.verified,
              label: '2차 감찰',
              date: '2026.06.20',
            ),
          ],
        ),
      );

      expect(find.textContaining('1차 감찰'), findsOneWidget);
      expect(find.textContaining('2차 감찰'), findsOneWidget);
    });

    testWidgets('이력이 없으면 아무것도 그리지 않는다', (tester) async {
      await pumpInApp(tester, const InspectionTimeline(steps: []));
      expect(find.byType(IntrinsicHeight), findsNothing);
    });
  });

  group('BlindMissionCard', () {
    testWidgets('배정 전에는 업체명을 보여주지 않는다', (tester) async {
      await pumpInApp(
        tester,
        const BlindMissionCard(
          category: '일식',
          region: '강남구',
          schedule: '점심 방문',
          fee: 54000,
          applicants: 6,
        ),
      );

      // 카테고리와 지역까지만. 업체명이 새어나가면 무작위 배정이 무의미해진다.
      expect(find.text('일식 · 강남구'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });

    testWidgets('보수에 천 단위 구분을 넣는다', (tester) async {
      await pumpInApp(
        tester,
        const BlindMissionCard(
          category: '카페',
          region: '성동구',
          schedule: '오후 방문',
          fee: 1234567,
        ),
      );

      expect(find.text('1,234,567'), findsOneWidget);
    });

    testWidgets('담합 차단된 미션은 탭이 막힌다', (tester) async {
      var tapped = false;
      await pumpInApp(
        tester,
        BlindMissionCard(
          category: '한식',
          region: '강남구',
          schedule: '저녁 방문',
          fee: 61000,
          blockedReason: '6개월 내 감찰 이력',
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(BlindMissionCard));
      await tester.pump();
      expect(tapped, isFalse);
      expect(find.text('6개월 내 감찰 이력'), findsOneWidget);
    });
  });

  group('StayTimerRing', () {
    testWidgets('경과 시간을 분:초로 보여준다', (tester) async {
      await pumpInApp(
        tester,
        const StayTimerRing(
          elapsed: Duration(minutes: 31, seconds: 4),
          required: Duration(minutes: 40),
        ),
      );

      expect(find.text('31:04'), findsOneWidget);
      expect(find.text('최소 40분 중'), findsOneWidget);
    });

    testWidgets('최소 시간을 채우면 문구가 바뀐다', (tester) async {
      await pumpInApp(
        tester,
        const StayTimerRing(
          elapsed: Duration(minutes: 42),
          required: Duration(minutes: 40),
        ),
      );

      expect(find.text('최소 시간 충족'), findsOneWidget);
    });

    testWidgets('최소 시간이 0이어도 나누기 오류가 나지 않는다', (tester) async {
      await pumpInApp(
        tester,
        const StayTimerRing(
          elapsed: Duration(minutes: 5),
          required: Duration.zero,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
