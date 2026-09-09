import 'dart:async';
import 'package:amhangeoheung_app/features/search/presentation/screens/search_screen.dart';
import 'package:amhangeoheung_app/core/theme/hwahae_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(BusinessSearch search) => MaterialApp(
    theme: HwahaeTheme.lightTheme, home: SearchScreen(search: search));

void main() {
  testWidgets('late search response cannot replace newer results',
      (tester) async {
    final old = Completer<List<Map<String, dynamic>>>();
    final latest = Completer<List<Map<String, dynamic>>>();
    await tester.pumpWidget(
        host((query, category) => query == 'old' ? old.future : latest.future));
    await tester.enterText(find.byType(TextFormField), 'old');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextFormField), 'new');
    await tester.pump(const Duration(milliseconds: 400));
    latest.complete([
      {'id': 'new', 'name': 'NEW RESULT'}
    ]);
    await tester.pumpAndSettle();
    old.complete([
      {'id': 'old', 'name': 'OLD RESULT'}
    ]);
    await tester.pumpAndSettle();
    expect(find.text('NEW RESULT'), findsOneWidget);
    expect(find.text('OLD RESULT'), findsNothing);
  });

  testWidgets('clearing input cancels pending debounce and in-flight response',
      (tester) async {
    final pending = Completer<List<Map<String, dynamic>>>();
    var calls = 0;
    await tester.pumpWidget(host((query, category) {
      calls++;
      return pending.future;
    }));
    await tester.enterText(find.byType(TextFormField), 'old');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byTooltip('검색어 지우기'));
    pending.complete([
      {'id': 'old', 'name': 'OLD RESULT'}
    ]);
    await tester.pumpAndSettle();
    expect(find.text('OLD RESULT'), findsNothing);
    expect(calls, 1);
    await tester.enterText(find.byType(TextFormField), 'cancel');
    await tester.pump();
    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(calls, 1);
  });

  testWidgets('category discovery searches without a name and preserves errors',
      (tester) async {
    String? requestedCategory;
    await tester.pumpWidget(host((query, category) async {
      requestedCategory = category;
      throw StateError('offline');
    }));
    await tester.tap(find.widgetWithText(ChoiceChip, '카페'));
    await tester.pumpAndSettle();
    expect(requestedCategory, '카페');
    expect(find.text('검색 결과를 불러오지 못했어요.'), findsOneWidget);
    expect(find.text('조건에 맞는 가게가 없어요'), findsNothing);
  });

  testWidgets('zero reviews never displays a made-up average', (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: HwahaeTheme.lightTheme,
        home: Scaffold(
            body: BusinessSearchCard(business: const {
          'id': 'business',
          'name': 'No reviews',
          'total_reviews': 0,
          'average_rating': 5,
        }, onTap: () {}))));
    expect(find.text('리뷰 0개'), findsOneWidget);
    expect(find.textContaining('평균'), findsNothing);
  });
}
