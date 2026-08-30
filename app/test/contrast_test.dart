import 'dart:math' as math;

import 'package:amhangeoheung_app/core/theme/hwahae_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.1 상대 명도 대비.
///
/// 팔레트를 보라에서 호랭이 털색으로 바꿀 때, 흰 글자를 그대로 둔 자리가 있어
/// 주 버튼 라벨이 1.86:1 까지 떨어졌었다. 색은 언제든 다시 조정되므로
/// 눈으로 보는 대신 숫자로 잠가둔다.
double contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = math.max(la, lb);
  final double lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// 본문 크기 글자 기준
const double kBodyMin = 4.5;

/// 큰 글씨(18.66px 굵게 / 24px 이상)와 아이콘 등 비텍스트 요소 기준
const double kLargeMin = 3.0;

void main() {
  group('본문 3단 램프', () {
    const bg = HwahaeColors.background;

    test('세 단계 모두 크림 배경에서 본문 기준을 넘는다', () {
      expect(contrast(HwahaeColors.textPrimary, bg),
          greaterThanOrEqualTo(kBodyMin));
      expect(contrast(HwahaeColors.textSecondary, bg),
          greaterThanOrEqualTo(kBodyMin));
      expect(contrast(HwahaeColors.textTertiary, bg),
          greaterThanOrEqualTo(kBodyMin));
    });

    test('단계가 실제로 구분된다', () {
      final p = contrast(HwahaeColors.textPrimary, bg);
      final s = contrast(HwahaeColors.textSecondary, bg);
      final t = contrast(HwahaeColors.textTertiary, bg);
      expect(p, greaterThan(s));
      expect(s, greaterThan(t));
    });
  });

  group('면 위의 글자', () {
    test('골드 면 — onPrimary', () {
      expect(contrast(HwahaeColors.onPrimary, HwahaeColors.primary),
          greaterThanOrEqualTo(kBodyMin));
    });

    test('골드 면에 흰 글자를 쓰면 안 된다', () {
      // 회귀 방지: 이 조합이 실제로 배포될 뻔했다.
      expect(contrast(Colors.white, HwahaeColors.primary), lessThan(kLargeMin));
    });

    test('연한 골드 면 — onPrimaryContainer', () {
      expect(
        contrast(HwahaeColors.onPrimaryContainer, HwahaeColors.primaryContainer),
        greaterThanOrEqualTo(kBodyMin),
      );
    });

    test('연한 붉은 면 — onSecondaryContainer', () {
      expect(
        contrast(
            HwahaeColors.onSecondaryContainer, HwahaeColors.secondaryContainer),
        greaterThanOrEqualTo(kBodyMin),
      );
    });

    test('연한 풀색 면 — onAccentContainer', () {
      expect(
        contrast(HwahaeColors.onAccentContainer, HwahaeColors.accentContainer),
        greaterThanOrEqualTo(kBodyMin),
      );
    });

    test('위험 버튼 — errorStrong 위의 크림 글자', () {
      expect(contrast(HwahaeColors.textOnDark, HwahaeColors.errorStrong),
          greaterThanOrEqualTo(kBodyMin));
    });

    test('먹 면 — 토스트 본문', () {
      expect(contrast(HwahaeColors.textOnDark, HwahaeColors.textPrimary),
          greaterThanOrEqualTo(kBodyMin));
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
          contrast(HwahaeColors.onColor(surface), surface),
          greaterThanOrEqualTo(kLargeMin),
          reason: '$surface 위의 글자 대비가 모자란다',
        );
      }
    });
  });
}
