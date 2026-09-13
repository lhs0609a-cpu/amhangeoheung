import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amhangeoheung_app/shared/widgets/content_image.dart';
import 'package:amhangeoheung_app/shared/widgets/discovery_banner.dart';
import 'package:amhangeoheung_app/features/trust/presentation/screens/trust_analysis_screen.dart';

void main() {
  test('business photos accept uploaded objects and legacy URL arrays', () {
    expect(
        ContentImage.firstUrl([
          {'url': 'https://example.com/photo.jpg', 'caption': '매장'}
        ]),
        'https://example.com/photo.jpg');
    expect(ContentImage.firstUrl(['', 'https://example.com/old.jpg']),
        'https://example.com/old.jpg');
    expect(
        ContentImage.firstUrl([
          null,
          {'caption': 'missing'},
          42
        ]),
        isNull);
    expect(ContentImage.firstUrl(null), isNull);
  });

  testWidgets('discovery artwork fits a narrow screen with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(
          size: Size(320, 900), textScaler: TextScaler.linear(1.5)),
      child:
          const Scaffold(body: SingleChildScrollView(child: DiscoveryBanner())),
    )));
    expect(tester.takeException(), isNull);
    expect(find.text('이제, 어사가\n직접 확인합니다.'), findsOneWidget);
  });

  testWidgets('zero reviews show an empty state without a fabricated grade',
      (tester) async {
    final data = TrustAnalysisData(
      businessName: '테스트 업체',
      badgeLevel: 'none',
      overallScore: 0,
      totalReviews: 0,
      verifiedReviews: 0,
      categoryScores: {},
      monthlyTrend: [],
      ratingDistribution: [],
      strengths: [],
      weaknesses: [],
      competitorComparison: CompetitorComparison(
          myScore: 0,
          categoryAverage: 0,
          topPerformer: 0,
          rankInCategory: 0,
          totalInCategory: 1),
    );
    await tester.pumpWidget(ProviderScope(
        overrides: [
          trustAnalysisProvider('empty').overrideWith((ref) async => data),
        ],
        child:
            const MaterialApp(home: TrustAnalysisScreen(businessId: 'empty'))));
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 게시된 리뷰가 없어요'), findsOneWidget);
    expect(find.text('D'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trust API failure offers retry rather than a zero score',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [
          trustAnalysisProvider('error')
              .overrideWith((ref) async => throw StateError('offline')),
        ],
        child:
            const MaterialApp(home: TrustAnalysisScreen(businessId: 'error'))));
    await tester.pumpAndSettle();
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.text('종합 신뢰도 점수'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
