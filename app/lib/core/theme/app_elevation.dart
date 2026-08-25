import 'package:flutter/material.dart';
import 'hwahae_colors.dart';

/// 그림자(고도) 시스템.
///
/// 기존 HwahaeTheme.shadow* 는 브랜드 보라색을 그대로 그림자에 썼는데, 흰 카드가
/// 겹치면 보랏빛이 누적돼 탁해 보인다. 여기서는 중립 그림자를 기본으로 두고,
/// 강조가 필요한 곳에만 브랜드 컬러 글로우를 따로 얹는다.
class AppElevation {
  AppElevation._();

  static const Color _shadowTint = Color(0xFF1A1A2E);

  /// 배경에서 살짝 떠 있는 정도. 리스트 카드, 칩.
  static List<BoxShadow> get level1 => [
        BoxShadow(
          color: _shadowTint.withValues(alpha: 0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: _shadowTint.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// 기본 카드. 배경과 확실히 분리된다.
  static List<BoxShadow> get level2 => [
        BoxShadow(
          color: _shadowTint.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: _shadowTint.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// 떠 있는 요소. 하단 네비게이션, 스티키 액션 바.
  static List<BoxShadow> get level3 => [
        BoxShadow(
          color: _shadowTint.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: _shadowTint.withValues(alpha: 0.08),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];

  /// 모달/시트 레이어.
  static List<BoxShadow> get level4 => [
        BoxShadow(
          color: _shadowTint.withValues(alpha: 0.10),
          blurRadius: 40,
          offset: const Offset(0, 20),
        ),
      ];

  /// 브랜드 컬러 글로우 - 주요 CTA 버튼 전용.
  /// 그림자가 아니라 "빛나는" 느낌이라 남용하면 싸구려로 보인다. CTA 하나에만.
  static List<BoxShadow> glow(Color color, {double strength = 1.0}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.28 * strength),
          blurRadius: 20 * strength,
          offset: Offset(0, 8 * strength),
        ),
      ];

  /// 눌린 상태 - 그림자를 거의 없애 표면에 붙는 느낌을 준다.
  static List<BoxShadow> get pressed => [
        BoxShadow(
          color: _shadowTint.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
}

/// 반투명 표면(글래스) 토큰.
class AppGlass {
  AppGlass._();

  /// 스크롤 콘텐츠 위에 얹히는 앱바/헤더 배경
  static Color get surface => HwahaeColors.surface.withValues(alpha: 0.82);

  /// 모달 뒤 어두운 막
  static Color get scrim => const Color(0xFF0B0B14).withValues(alpha: 0.45);

  /// 이미지 위 텍스트 가독성용 그라디언트
  static const LinearGradient readabilityScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00000000),
      Color(0x40000000),
      Color(0xB3000000),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// 유리 표면 테두리
  static Border get border => Border.all(
        color: Colors.white.withValues(alpha: 0.55),
        width: 1,
      );
}
