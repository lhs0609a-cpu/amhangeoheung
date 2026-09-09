import 'dart:io';
import 'package:amhangeoheung_app/core/theme/hwahae_theme.dart';
import 'package:amhangeoheung_app/core/services/connectivity_service.dart';
import 'package:amhangeoheung_app/features/home/presentation/screens/home_screen.dart';
import 'package:amhangeoheung_app/features/home/providers/home_provider.dart';
import 'package:amhangeoheung_app/features/review/data/models/review_model.dart';
import 'package:amhangeoheung_app/features/review/data/repositories/review_repository.dart';
import 'package:amhangeoheung_app/features/mission/data/repositories/mission_repository.dart';
import 'package:amhangeoheung_app/features/ranking/data/repositories/ranking_repository.dart';
import 'package:amhangeoheung_app/features/search/presentation/screens/search_screen.dart';
import 'package:amhangeoheung_app/features/trust/presentation/screens/trust_analysis_screen.dart';
import 'package:amhangeoheung_app/shared/widgets/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const previews = bool.fromEnvironment('GENERATE_PREVIEWS');
final review = ReviewModel(
    id: 'review',
    missionId: 'mission',
    businessId: 'business',
    reviewerId: 'reviewer',
    status: 'published',
    totalScore: 3.8,
    createdAt: DateTime(2026, 9, 8),
    publishedAt: DateTime(2026, 9, 8),
    business: BusinessInfo(
        id: 'business',
        name: '예시 카페 · 테스트 데이터',
        category: '카페',
        addressCity: '서울 마포구'),
    summary: '조용한 공간에서 읽은, 직접 방문한 이야기',
    pros: ['주문한 메뉴와 결제 금액이 일치했어요.'],
    cons: ['테이블 정리까지 기다리는 시간이 있었어요.']);

class StaticHome extends HomeDataNotifier {
  StaticHome()
      : super(ReviewRepository(), MissionRepository(), RankingRepository()) {
    state = HomeDataState(isLoading: false, recentReviews: [review]);
  }
  @override
  Future<void> loadHomeData({String? category, bool? includeMissions}) async {}
}

Future<void> decode(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final font = FontLoader('Jua')
      ..addFont(rootBundle.load('assets/fonts/Jua-Regular.ttf'));
    await font.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    // Local previews use the installed Korean body font; not bundled into the app.
    final path = File('C:/Windows/Fonts/malgun.ttf');
    if (previews && path.existsSync()) {
      final bytes = await path.readAsBytes();
      for (final family in ['Roboto', 'Malgun Gothic', 'Apple SD Gothic Neo', 'Noto Sans KR']) {
        await (FontLoader(family)
              ..addFont(Future.value(ByteData.sublistView(bytes))))
            .load();
      }
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'user_type_preference': 'consumer'});
  });

  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('home fits ${width.toInt()}px at ${scale}x text',
          (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final router = GoRouter(initialLocation: '/home', routes: [
          GoRoute(
              path: '/home',
              builder: (_, __) => const MainScaffold(child: HomeScreen())),
        ]);
        addTearDown(router.dispose);
        await tester.pumpWidget(ProviderScope(
            overrides: [
              connectivityProvider.overrideWith((ref) => Stream.value(true)),
              homeDataProvider.overrideWith((ref) => StaticHome())
            ],
            child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                routerConfig: router,
                theme: HwahaeTheme.lightTheme,
                builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!))));
        await decode(tester);
        expect(tester.takeException(), isNull);
        if (previews && width == 390 && scale == 1) {
          await expectLater(find.byType(MaterialApp),
              matchesGoldenFile('../../docs/qa/home.png'));
        }
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -650));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('search preview uses real result widget', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: HwahaeTheme.lightTheme,
        home: SearchScreen(
            initialCategory: '카페',
            search: (_, __) async => [
                  {
                    'id': 'example',
                    'name': '예시 카페 · 테스트 데이터',
                    'category': '카페',
                    'address_city': '서울 마포구',
                    'total_reviews': 12,
                    'average_rating': 3.8
                  }
                ])));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (previews) {
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../../docs/qa/search.png'));
    }
  });

  testWidgets(
      'report distinguishes legacy improvement and has no fake certification',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          trustAnalysisProvider('example').overrideWith(
              (ref) async => PublicInspectionReport(summary: const {
                    'businessName': '예시 카페 · 테스트 데이터',
                    'category': '카페',
                    'totalReviews': 12,
                    'averageScore': 3.8,
                    'findingsAvailable': true,
                    'findings': [
                      {
                        'title': '테이블 정리 대기',
                        'status': 'open',
                        'first_found_at': '2026-09-08',
                        'promise': '정리 담당자를 배치하겠습니다.'
                      },
                      {
                        'title': '대기 안내',
                        'status': 'fixed',
                        'first_found_at': '2026-09-01'
                      },
                    ],
                  }, reviews: [
                    review
                  ]))
        ],
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: HwahaeTheme.lightTheme,
            home: const TrustAnalysisScreen(businessId: 'example'))));
    await tester.pumpAndSettle();
    expect(find.text('개선 확인 대기'), findsOneWidget);
    expect(find.text('개선 처리 기록'), findsOneWidget);
    expect(find.text('고침'), findsNothing);
    expect(tester.takeException(), isNull);
    if (previews) {
      await expectLater(find.byType(MaterialApp),
          matchesGoldenFile('../../docs/qa/report.png'));
    }
  });
}
