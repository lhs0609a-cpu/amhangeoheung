import 'dart:math' as math;

import 'package:flutter/material.dart';

/// WCAG 2.1 상대 명도 대비.
///
/// 팔레트를 보라에서 호랭이 털색으로 바꿀 때, 흰 글자를 그대로 둔 자리가 있어
/// 주 버튼 라벨이 1.86:1 까지 떨어졌었다. 색은 언제든 다시 조정되므로
/// 눈으로 보는 대신 숫자로 잠가둔다.
///
/// 토큰을 검사하는 쪽(`contrast_test.dart`)과 위젯이 실제로 그린 색을 검사하는
/// 쪽(`ui_kit_test.dart`)이 같은 자를 써야 해서 여기로 뺐다.
double contrastRatio(Color a, Color b) {
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
