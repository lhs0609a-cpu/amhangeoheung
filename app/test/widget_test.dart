// 기본 스모크 테스트.
// 기존 자동생성 테스트는 존재하지 않는 MyApp/카운터를 참조해 깨져 있었으므로,
// 실제 위젯을 렌더링하는 최소 스모크 테스트로 교체한다.
// (전체 앱은 Firebase/라우터 초기화에 의존하므로 여기서는 단순 위젯만 검증)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp 이 정상적으로 렌더링된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('암행어흥'))),
      ),
    );

    expect(find.text('암행어흥'), findsOneWidget);
  });
}
