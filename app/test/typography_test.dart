import 'package:amhangeoheung_app/core/theme/hwahae_typography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('표시 서체 폴백', () {
    test('Jua 를 쓰는 스타일에는 반드시 폴백이 붙어 있다', () {
      // Jua 에는 가운뎃점(·)이 없다. 폴백이 빠지면 '현장 도착 · 체크인' 의
      // · 가 두부(□)로 찍힌다 — 실제로 버튼 라벨에서 그렇게 나왔다.
      final juaStyles = {
        'displayLarge': HwahaeTypography.displayLarge,
        'displayMedium': HwahaeTypography.displayMedium,
        'displaySmall': HwahaeTypography.displaySmall,
        'headlineLarge': HwahaeTypography.headlineLarge,
        'headlineMedium': HwahaeTypography.headlineMedium,
        'headlineSmall': HwahaeTypography.headlineSmall,
        'button': HwahaeTypography.button,
        'buttonSmall': HwahaeTypography.buttonSmall,
        'chip': HwahaeTypography.chip,
        'badge': HwahaeTypography.badge,
        'price': HwahaeTypography.price,
        'priceSmall': HwahaeTypography.priceSmall,
        'bottomNav': HwahaeTypography.bottomNav,
      };

      for (final entry in juaStyles.entries) {
        expect(entry.value.fontFamily, HwahaeTypography.fontFamilyDisplay,
            reason: '${entry.key} 가 표시 서체를 쓰지 않는다');
        expect(entry.value.fontFamilyFallback, isNotEmpty,
            reason: '${entry.key} 에 폴백이 없어 없는 글리프가 두부로 찍힌다');
      }
    });

    test('Jua 는 단일 웨이트라 굵기를 합성하지 않는다', () {
      // w500 이상을 주면 Flutter 가 가짜 볼드를 그려 글자가 뭉갠다.
      for (final style in [
        HwahaeTypography.displayLarge,
        HwahaeTypography.headlineMedium,
        HwahaeTypography.button,
        HwahaeTypography.badge,
      ]) {
        expect(style.fontWeight!.index, lessThanOrEqualTo(3),
            reason: 'Jua 스타일의 굵기가 w400 을 넘는다');
      }
    });

    test('본문은 시스템 서체를 쓴다 — 없는 서체를 선언하지 않는다', () {
      // 예전에 'Pretendard' 로 선언돼 있었지만 자산이 없어 조용히 폴백됐다.
      expect(HwahaeTypography.fontFamily, isNull);
    });
  });
}
