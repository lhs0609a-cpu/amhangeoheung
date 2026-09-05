import 'package:amhangeoheung_app/core/theme/dark_theme_colors.dart';
import 'package:amhangeoheung_app/core/theme/hwahae_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/contrast.dart';

/// 이 파일은 토큰만 검사한다. 위젯이 그 토큰을 실제로 쓰는지는
/// `ui_kit_test.dart` 가 렌더링된 색을 꺼내서 검사한다.

void main() {
  group('본문 3단 램프', () {
    const bg = HwahaeColors.background;

    test('세 단계 모두 크림 배경에서 본문 기준을 넘는다', () {
      expect(contrastRatio(HwahaeColors.textPrimary, bg),
          greaterThanOrEqualTo(kBodyMin));
      expect(contrastRatio(HwahaeColors.textSecondary, bg),
          greaterThanOrEqualTo(kBodyMin));
      expect(contrastRatio(HwahaeColors.textTertiary, bg),
          greaterThanOrEqualTo(kBodyMin));
    });

    test('단계가 실제로 구분된다', () {
      final p = contrastRatio(HwahaeColors.textPrimary, bg);
      final s = contrastRatio(HwahaeColors.textSecondary, bg);
      final t = contrastRatio(HwahaeColors.textTertiary, bg);
      expect(p, greaterThan(s));
      expect(s, greaterThan(t));
    });
  });

  group('면 위의 글자', () {
    test('골드 면 — onPrimary', () {
      expect(contrastRatio(HwahaeColors.onPrimary, HwahaeColors.primary),
          greaterThanOrEqualTo(kBodyMin));
    });

    test('골드 면에 흰 글자를 쓰면 안 된다', () {
      // 회귀 방지: 이 조합이 실제로 배포될 뻔했다.
      expect(contrastRatio(Colors.white, HwahaeColors.primary), lessThan(kLargeMin));
    });

    test('연한 골드 면 — onPrimaryContainer', () {
      expect(
        contrastRatio(HwahaeColors.onPrimaryContainer, HwahaeColors.primaryContainer),
        greaterThanOrEqualTo(kBodyMin),
      );
    });

    test('연한 붉은 면 — onSecondaryContainer', () {
      expect(
        contrastRatio(
            HwahaeColors.onSecondaryContainer, HwahaeColors.secondaryContainer),
        greaterThanOrEqualTo(kBodyMin),
      );
    });

    test('연한 풀색 면 — onAccentContainer', () {
      expect(
        contrastRatio(HwahaeColors.onAccentContainer, HwahaeColors.accentContainer),
        greaterThanOrEqualTo(kBodyMin),
      );
    });

    test('위험 버튼 — errorStrong 위의 크림 글자', () {
      expect(contrastRatio(HwahaeColors.textOnDark, HwahaeColors.errorStrong),
          greaterThanOrEqualTo(kBodyMin));
    });

    test('먹 면 — 토스트 본문', () {
      expect(contrastRatio(HwahaeColors.textOnDark, HwahaeColors.textPrimary),
          greaterThanOrEqualTo(kBodyMin));
    });
  });

  group('밝은 면 위의 브랜드 색', () {
    // 골드를 글자·아이콘 색으로 쓰면 흰 바탕에서 1.86:1 이다. 화면 100여
    // 곳이 그렇게 돼 있었다. 밝은 면 위의 브랜드 강조는 onPrimaryContainer
    // 를 쓴다.
    test('골드를 밝은 면의 글자색으로 쓰면 안 된다', () {
      expect(contrastRatio(HwahaeColors.primary, HwahaeColors.surface),
          lessThan(kLargeMin));
      expect(contrastRatio(HwahaeColors.primary, HwahaeColors.background),
          lessThan(kLargeMin));
    });

    test('onPrimaryContainer 는 흰 면과 크림 면 모두에서 본문 기준을 넘는다', () {
      expect(
          contrastRatio(
              HwahaeColors.onPrimaryContainer, HwahaeColors.surface),
          greaterThanOrEqualTo(kBodyMin));
      expect(
          contrastRatio(
              HwahaeColors.onPrimaryContainer, HwahaeColors.background),
          greaterThanOrEqualTo(kBodyMin));
    });

    test('골드는 먹색 면 위에서는 오히려 잘 읽힌다', () {
      // 다크 카드에서 골드를 금지하면 안 된다 — 거기서는 맞는 선택이다.
      expect(contrastRatio(HwahaeColors.primary, HwahaeColors.textPrimary),
          greaterThanOrEqualTo(kBodyMin));
    });
  });

  group('골드 면 위의 글자', () {
    // 그라디언트는 양 끝 색이 다르다. 한쪽 끝에서만 읽히면 반쪽짜리다.
    test('onPrimary 는 브랜드 그라디언트 전 구간에서 읽힌다', () {
      for (final stop in [
        ...HwahaeColors.gradientPrimary,
        ...HwahaeColors.gradientWarm,
      ]) {
        expect(
          contrastRatio(HwahaeColors.onPrimary, stop),
          greaterThanOrEqualTo(kBodyMin),
          reason: '$stop 위에서 onPrimary 가 모자란다',
        );
      }
    });

    test('흰 글자는 그라디언트 어느 구간에서도 기준에 못 미친다', () {
      for (final stop in [
        ...HwahaeColors.gradientPrimary,
        ...HwahaeColors.gradientWarm,
      ]) {
        expect(contrastRatio(Colors.white, stop), lessThan(kBodyMin));
      }
    });
  });

  group('onColor 자동 선택', () {
    test('밝은 면에는 먹색, 어두운 면에는 크림색을 고른다', () {
      expect(HwahaeColors.onColor(HwahaeColors.primary),
          HwahaeColors.textPrimary);
      expect(HwahaeColors.onColor(HwahaeColors.textPrimary),
          HwahaeColors.textOnDark);
    });

    test('고른 색은 항상 본문 기준을 넘는다', () {
      const surfaces = <Color>[
        HwahaeColors.primary,
        HwahaeColors.secondary,
        HwahaeColors.accent,
        HwahaeColors.textPrimary,
        HwahaeColors.missionRegular,
        HwahaeColors.missionHidden,
        HwahaeColors.missionSeason,
        HwahaeColors.missionUrgent,
        HwahaeColors.missionPremium,
        HwahaeColors.gradeRookie,
        HwahaeColors.gradeBronze,
        HwahaeColors.gradeSilver,
        HwahaeColors.gradeGold,
        HwahaeColors.gradePlatinum,
        HwahaeColors.gradeDiamond,
      ];
      for (final surface in surfaces) {
        expect(
          contrastRatio(HwahaeColors.onColor(surface), surface),
          greaterThanOrEqualTo(kLargeMin),
          reason: '$surface 위의 글자 대비가 모자란다',
        );
      }
    });
  });

  group('조작 요소 경계 (WCAG 1.4.11)', () {
    test('라이트 — borderStrong 이 페이지 배경에서 구분된다', () {
      expect(
        contrastRatio(HwahaeColors.borderStrong, HwahaeColors.background),
        greaterThanOrEqualTo(kLargeMin),
      );
    });

    test('다크 — borderStrong 이 페이지 배경에서 구분된다', () {
      expect(
        contrastRatio(DarkThemeColors.borderStrong, DarkThemeColors.background),
        greaterThanOrEqualTo(kLargeMin),
      );
    });

    test('입력창 채움만으로는 경계가 보이지 않는다', () {
      // 회귀 방지: 이 값이 3:1 을 넘게 되면 테두리 없이도 되지만,
      // 지금은 1.11:1 이라 enabledBorder 가 반드시 있어야 한다.
      expect(
        contrastRatio(HwahaeColors.surfaceVariant, HwahaeColors.background),
        lessThan(kLargeMin),
      );
    });
  });

  group('다크 모드', () {
    const bg = DarkThemeColors.background;
    const surface = DarkThemeColors.surface;

    test('본문 3단이 배경에서 본문 기준을 넘는다', () {
      expect(contrastRatio(DarkThemeColors.textPrimary, bg),
          greaterThanOrEqualTo(kBodyMin));
      expect(contrastRatio(DarkThemeColors.textSecondary, bg),
          greaterThanOrEqualTo(kBodyMin));
      expect(contrastRatio(DarkThemeColors.textTertiary, bg),
          greaterThanOrEqualTo(kBodyMin));
    });

    test('본문 3단이 카드면에서도 본문 기준을 넘는다', () {
      expect(contrastRatio(DarkThemeColors.textPrimary, surface),
          greaterThanOrEqualTo(kBodyMin));
      expect(contrastRatio(DarkThemeColors.textSecondary, surface),
          greaterThanOrEqualTo(kBodyMin));
      expect(contrastRatio(DarkThemeColors.textTertiary, surface),
          greaterThanOrEqualTo(kBodyMin));
    });

    test('브랜드 색이 어두운 배경에서 읽힌다', () {
      for (final c in <Color>[
        DarkThemeColors.primary,
        DarkThemeColors.secondary,
        DarkThemeColors.accent,
        DarkThemeColors.warning,
        DarkThemeColors.error,
        DarkThemeColors.success,
      ]) {
        expect(contrastRatio(c, bg), greaterThanOrEqualTo(kBodyMin),
            reason: '$c 가 어두운 배경에서 모자란다');
      }
    });

    test('골드 면 위의 글자는 어두운 색이다', () {
      expect(contrastRatio(DarkThemeColors.onPrimary, DarkThemeColors.primary),
          greaterThanOrEqualTo(kBodyMin));
    });

    test('다크 배경은 순검정이 아니다', () {
      // 순검정 위의 금색은 싸구려 금박처럼 보인다.
      expect(bg, isNot(const Color(0xFF000000)));
      expect(bg.computeLuminance(), greaterThan(0.0));
    });
  });
}
