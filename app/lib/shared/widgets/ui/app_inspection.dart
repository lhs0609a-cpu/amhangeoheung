import 'package:flutter/material.dart';

import '../../../core/theme/app_elevation.dart';
import '../../../core/theme/hwahae_colors.dart';
import '../../../core/theme/hwahae_theme.dart';
import '../../../core/theme/hwahae_typography.dart';

/// 감찰 도메인 위젯.
///
/// 이 파일의 위젯들은 "업체가 돈을 내지만 업체가 결과를 못 바꾼다" 는 제품의
/// 주장을 화면으로 드러내는 것들이다. 그래서 여기에는 캐릭터를 쓰지 않는다 —
/// 판정이 걸린 화면에서 캐릭터가 웃고 있으면 지적이 농담처럼 읽힌다.

// ─────────────────────────────────────────────────────────────────────────────
// 지적사항
// ─────────────────────────────────────────────────────────────────────────────

/// 감찰에서 지적된 항목 하나.
class InspectionFinding {
  const InspectionFinding({
    required this.title,
    this.detail,
    this.fixed = false,
  });

  final String title;
  final String? detail;

  /// 재감찰에서 개선이 확인됐는지.
  final bool fixed;
}

/// 지적사항 카드.
///
/// 고쳐진 항목과 안 고쳐진 항목이 **같은 목록에 나란히** 놓이는 것이 핵심이다.
/// 안 고쳐진 것을 접거나 뒤로 미루면 업체가 결과를 바꾼 것과 같아진다.
class FindingCard extends StatelessWidget {
  const FindingCard({super.key, required this.finding, this.onTap});

  final InspectionFinding finding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool fixed = finding.fixed;
    final Color edge = fixed ? HwahaeColors.border : HwahaeColors.secondary;
    final Color chipBg =
        fixed ? HwahaeColors.accentContainer : HwahaeColors.secondaryContainer;
    final Color chipInk = fixed
        ? HwahaeColors.onAccentContainer
        : HwahaeColors.onSecondaryContainer;

    return Semantics(
      label: '${finding.title}, ${fixed ? '개선 확인됨' : '아직 개선되지 않음'}',
      button: onTap != null,
      // blur 0 그림자는 단색 도형이라, decoration 에 채움색이 없으면 부모
      // Material 이 칠한 흰색을 그대로 덮어버린다. 채움은 반드시 decoration
      // 안에 두고 Material 은 잉크 효과용으로만 투명하게 남긴다.
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            decoration: BoxDecoration(
              color: HwahaeColors.surface,
              borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
              border: Border.all(color: edge, width: 2),
              boxShadow: AppElevation.sticker(
                3,
                color: fixed
                    ? HwahaeColors.stickerShadow
                    : HwahaeColors.secondaryContainer,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(color: chipBg, shape: BoxShape.circle),
                  child: Icon(
                    fixed
                        ? Icons.check_rounded
                        : Icons.priority_high_rounded,
                    size: 16,
                    color: chipInk,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(finding.title, style: HwahaeTypography.titleSmall),
                      if (finding.detail != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          finding.detail!,
                          style: HwahaeTypography.captionMedium
                              .copyWith(color: HwahaeColors.textTertiary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius:
                        BorderRadius.circular(HwahaeTheme.radiusFull),
                  ),
                  child: Text(
                    fixed ? '고침' : '아직',
                    style: HwahaeTypography.chip.copyWith(color: chipInk),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 감찰 이력 — 개선 서사
// ─────────────────────────────────────────────────────────────────────────────

enum InspectionStepKind {
  /// 감찰에서 지적됨
  finding,

  /// 업체가 개선을 약속함
  promise,

  /// 재감찰에서 개선이 확인됨
  verified,
}

class InspectionStep {
  const InspectionStep({
    required this.kind,
    required this.label,
    required this.date,
    this.detail,
  });

  final InspectionStepKind kind;
  final String label;
  final String date;
  final String? detail;
}

/// 감찰 이력 타임라인.
///
/// 이 제품이 다른 리뷰 플랫폼과 구분되는 지점이다. 별점은 어디에나 있지만
/// **"지적했다 → 약속했다 → 다시 가보니 고쳤더라"** 는 재감찰에 응할 이유가
/// 있는 업체에서만 나온다. 그래서 화면에서도 별점보다 위에 둔다.
class InspectionTimeline extends StatelessWidget {
  const InspectionTimeline({super.key, required this.steps});

  final List<InspectionStep> steps;

  Color _dotColor(InspectionStepKind kind) {
    switch (kind) {
      case InspectionStepKind.finding:
        return HwahaeColors.secondary;
      case InspectionStepKind.promise:
        return HwahaeColors.textTertiary;
      case InspectionStepKind.verified:
        return HwahaeColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 12,
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: _dotColor(steps[i].kind),
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (i != steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            color: HwahaeColors.border,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i == steps.length - 1 ? 0 : 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${steps[i].label} · ${steps[i].date}',
                          style: HwahaeTypography.titleSmall,
                        ),
                        if (steps[i].detail != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            steps[i].detail!,
                            style: HwahaeTypography.captionMedium
                                .copyWith(color: HwahaeColors.textTertiary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 블라인드 미션 카드
// ─────────────────────────────────────────────────────────────────────────────

/// 모집 중인 감찰 카드.
///
/// 배정 전에는 업체명을 보여주지 않는다. 업체명을 먼저 알면 감찰관이 골라
/// 지원하게 되고, 그러면 "무작위 배정" 이 무의미해진다. 카테고리와 지역까지만
/// 공개하는 것이 담합을 막는 첫 번째 장치다.
class BlindMissionCard extends StatelessWidget {
  const BlindMissionCard({
    super.key,
    required this.category,
    required this.region,
    required this.schedule,
    required this.fee,
    this.applicants,
    this.deadline,
    this.blockedReason,
    this.onTap,
  });

  final String category;
  final String region;

  /// "점심 방문 · 최소 체류 40분"
  final String schedule;

  /// 등급 배율이 반영된 최종 보수(원)
  final int fee;

  final int? applicants;

  /// "마감까지 2일"
  final String? deadline;

  /// 지원할 수 없는 이유. 담합 방지로 막힌 경우 등.
  final String? blockedReason;

  final VoidCallback? onTap;

  String get _feeText {
    final s = fee.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bool blocked = blockedReason != null;

    return Semantics(
      label: '$category $region 감찰, 보수 $_feeText원'
          '${blocked ? ', 지원 불가' : ''}',
      button: !blocked && onTap != null,
      child: Opacity(
        opacity: blocked ? 0.75 : 1,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          child: InkWell(
            onTap: blocked ? null : onTap,
            borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: blocked
                    ? HwahaeColors.surfaceVariant
                    : HwahaeColors.surface,
                borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                border: Border.all(color: HwahaeColors.border, width: 2),
                boxShadow: blocked ? null : AppElevation.sticker(3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 업체 자리 — 자물쇠로 "아직 밝히지 않는다"를 보여준다.
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: HwahaeColors.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(HwahaeTheme.radiusSM),
                        ),
                        child: Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: HwahaeColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$category · $region',
                                style: HwahaeTypography.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              schedule,
                              style: HwahaeTypography.captionMedium
                                  .copyWith(color: HwahaeColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_feeText, style: HwahaeTypography.price),
                          const SizedBox(height: 4),
                          Text(
                            '등급 반영',
                            style: HwahaeTypography.captionSmall
                                .copyWith(color: HwahaeColors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (blocked) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.block_rounded,
                            size: 15, color: HwahaeColors.secondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            blockedReason!,
                            style: HwahaeTypography.captionMedium
                                .copyWith(color: HwahaeColors.secondary),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 13),
                    Container(height: 1, color: HwahaeColors.borderLight),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        if (applicants != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: HwahaeColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(
                                  HwahaeTheme.radiusFull),
                            ),
                            child: Text('지원 $applicants명',
                                style: HwahaeTypography.chip.copyWith(
                                    color: HwahaeColors.textSecondary)),
                          ),
                        if (deadline != null) ...[
                          const SizedBox(width: 9),
                          Text(
                            deadline!,
                            style: HwahaeTypography.captionMedium
                                .copyWith(color: HwahaeColors.textTertiary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 체류 타이머
// ─────────────────────────────────────────────────────────────────────────────

/// 현장 체류 시간 링.
///
/// 최소 체류 시간을 채우지 못하면 감찰이 무효가 된다. 남은 시간을 숨기면
/// 감찰관이 언제 나가도 되는지 몰라 불안해하므로, 진행률과 함께 크게 보여준다.
class StayTimerRing extends StatelessWidget {
  const StayTimerRing({
    super.key,
    required this.elapsed,
    required this.required,
    this.size = 236,
    this.onDark = true,
  });

  final Duration elapsed;
  final Duration required;
  final double size;

  /// 현장 화면은 먹색 배경 위에 놓인다.
  final bool onDark;

  double get _progress => required.inSeconds == 0
      ? 1
      : (elapsed.inSeconds / required.inSeconds).clamp(0.0, 1.0);

  bool get _met => elapsed >= required;

  String get _elapsedText {
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Color ink =
        onDark ? HwahaeColors.textOnDark : HwahaeColors.textPrimary;
    final Color sub =
        onDark ? HwahaeColors.textTertiary : HwahaeColors.textSecondary;
    final Color track =
        onDark ? HwahaeColors.textPrimary : HwahaeColors.surfaceContainer;
    final Color bar = _met ? HwahaeColors.accent : HwahaeColors.primary;

    return Semantics(
      label: '체류 시간 $_elapsedText, 최소 ${required.inMinutes}분 중'
          '${_met ? ', 충족됨' : ''}',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: size * 0.017,
                backgroundColor: track,
                valueColor: AlwaysStoppedAnimation<Color>(bar),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '체류 시간',
                  style: HwahaeTypography.overline.copyWith(color: sub),
                ),
                const SizedBox(height: 10),
                Text(
                  _elapsedText,
                  style: HwahaeTypography.displayLarge
                      .copyWith(color: ink, fontSize: size * 0.25),
                ),
                const SizedBox(height: 10),
                Text(
                  _met ? '최소 시간 충족' : '최소 ${required.inMinutes}분 중',
                  style: HwahaeTypography.captionMedium.copyWith(
                    color: _met ? HwahaeColors.accent : sub,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
