import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/hwahae_colors.dart';
import '../../../core/theme/hwahae_typography.dart';

/// 암행어흥 캐릭터.
///
/// - [AppMascot.eoheung] 갓 쓴 호랭이. 브랜드이자 안내자.
/// - [AppMascot.sato]    사람 사또. 감찰관(리뷰어)의 얼굴.
///
/// **쓰는 자리를 지킬 것.** 온보딩 · 빈 화면 · 안내 · 축하에만 쓴다.
/// 감찰 리포트 · 지적사항 · 업체 응답 · 결제처럼 판정이 걸린 화면에는
/// 올리지 않는다. 지적 옆에서 캐릭터가 웃고 있으면 지적이 농담처럼 읽히고,
/// 그러면 "돈을 받고도 정직하다"는 이 제품의 존재 이유가 무너진다.
/// 그런 화면에는 [SealBadge] 와 숫자만 둔다.
enum MascotKind {
  /// 갓 쓴 호랭이 — 브랜드
  eoheung(
    svg: 'assets/characters/eoheung.svg',
    png: 'assets/characters/eoheung.png',
    pngOnDark: 'assets/characters/eoheung_dark.png',
    label: '어흥이',
  ),

  /// 사또 — 감찰관
  sato(
    svg: 'assets/characters/sato.svg',
    png: 'assets/characters/sato.png',
    pngOnDark: 'assets/characters/sato_dark.png',
    label: '사또',
  );

  const MascotKind({
    required this.svg,
    required this.png,
    required this.pngOnDark,
    required this.label,
  });

  /// 작은 크기용 벡터. 탭바·목록 아바타처럼 40px 미만에서 쓴다.
  final String svg;

  /// 큰 크기용 그림. 밝은 배경에 올릴 때.
  final String png;

  /// 먹색 배경용. 갓 실루엣에 크림색 테두리가 둘러져 있어 배경에 묻히지 않는다.
  final String pngOnDark;

  final String label;
}

class AppMascot extends StatelessWidget {
  const AppMascot(
    this.kind, {
    super.key,
    this.size = 48,
    this.onDark = false,
    this.semanticLabel,
  });

  const AppMascot.eoheung({
    super.key,
    this.size = 48,
    this.onDark = false,
    this.semanticLabel,
  }) : kind = MascotKind.eoheung;

  const AppMascot.sato({
    super.key,
    this.size = 48,
    this.onDark = false,
    this.semanticLabel,
  }) : kind = MascotKind.sato;

  final MascotKind kind;
  final double size;

  /// 먹색 배경 위에 올리는지. 켜면 갓에 크림색 테두리가 둘러진 그림을 쓴다.
  /// 끄면 어두운 카드에서 갓이 배경에 묻혀 얼굴만 떠 있게 된다.
  final bool onDark;

  final String? semanticLabel;

  /// 이 크기 미만에서는 벡터를 쓴다.
  ///
  /// 그림은 512px 원본이라 큰 자리에서는 벡터보다 표정이 살지만, 탭바(26px)나
  /// 목록 아바타(34px)처럼 작은 자리에서는 축소하면서 수염·줄무늬가 뭉갠다.
  /// 그 크기에서는 디테일을 덜어낸 SVG 가 오히려 또렷하다.
  static const double rasterThreshold = 44;

  @override
  Widget build(BuildContext context) {
    final String label = semanticLabel ?? kind.label;

    if (size < rasterThreshold) {
      return SvgPicture.asset(
        kind.svg,
        width: size,
        height: size,
        semanticsLabel: label,
      );
    }

    return Image.asset(
      onDark ? kind.pngOnDark : kind.png,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: label,
    );
  }
}

/// 어흥이가 한마디 하는 말풍선 카드.
///
/// 빈 화면과 안내에 쓴다. [dark] 를 켜면 먹색 바탕이 되어 감찰관 화면처럼
/// 어두운 맥락에 맞는다.
class MascotMessage extends StatelessWidget {
  const MascotMessage({
    super.key,
    required this.message,
    this.detail,
    this.kind = MascotKind.eoheung,
    this.dark = false,
    this.onTap,
  });

  final String message;
  final String? detail;
  final MascotKind kind;
  final bool dark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color background =
        dark ? HwahaeColors.textPrimary : HwahaeColors.surfaceVariant;
    final Color titleColor =
        dark ? HwahaeColors.textOnDark : HwahaeColors.textPrimary;
    final Color detailColor =
        dark ? HwahaeColors.textTertiary : HwahaeColors.textSecondary;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              AppMascot(kind, size: 54, onDark: dark),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      style: HwahaeTypography.headlineSmall
                          .copyWith(color: titleColor),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        detail!,
                        style: HwahaeTypography.bodySmall
                            .copyWith(color: detailColor),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  // 먹색 카드 위에서는 골드가 맞다(5.7:1). 밝은 면에 쓰는
                  // onPrimaryContainer 를 여기 넣으면 어둠 위의 어둠이 된다.
                  color: dark
                      ? HwahaeColors.primary
                      : HwahaeColors.textTertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 감찰 인장.
///
/// 감찰이 끝난 업체에만 찍힌다. 횟수가 함께 새겨져 한 번과 다섯 번이 구분된다.
/// **돈으로 살 수 없다** — 구독 플랜은 이 도장을 팔지 않는다.
class SealBadge extends StatelessWidget {
  const SealBadge({
    super.key,
    required this.count,
    this.size = 76,
    this.tilted = true,
  });

  /// 감찰 횟수. 0 이면 아직 감찰되지 않은 업체이므로 인장을 그리지 않는다.
  final int count;
  final double size;

  /// 도장을 삐뚜름하게 찍은 느낌. 리스트처럼 정렬이 중요한 곳에서는 끈다.
  final bool tilted;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final double scale = size / 76;
    final Widget seal = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: HwahaeColors.sealBackground,
        shape: BoxShape.circle,
        border: Border.all(color: HwahaeColors.sealInk, width: 2.4 * scale),
      ),
      child: Center(
        child: Container(
          width: size - (12 * scale),
          height: size - (12 * scale),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: HwahaeColors.sealInk, width: 1 * scale),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '감찰',
                style: HwahaeTypography.headlineSmall.copyWith(
                  fontSize: 17 * scale,
                  height: 1.0,
                  color: HwahaeColors.sealInk,
                ),
              ),
              SizedBox(height: 3 * scale),
              Text(
                '$count회',
                style: HwahaeTypography.captionMedium.copyWith(
                  fontFamily: HwahaeTypography.fontFamilyDisplay,
                  fontSize: 13 * scale,
                  height: 1.0,
                  color: HwahaeColors.sealInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!tilted) return seal;
    return Transform.rotate(angle: -0.12, child: seal);
  }
}
