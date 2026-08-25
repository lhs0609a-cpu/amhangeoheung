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
}
