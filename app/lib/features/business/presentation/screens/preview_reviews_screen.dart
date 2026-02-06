import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';

/// 선공개 리뷰 화면 (업체용)
/// 72시간 선공개 프로세스 시각화
class PreviewReviewsScreen extends ConsumerStatefulWidget {
  const PreviewReviewsScreen({super.key});

  @override
  ConsumerState<PreviewReviewsScreen> createState() => _PreviewReviewsScreenState();
}

class _PreviewReviewsScreenState extends ConsumerState<PreviewReviewsScreen> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // 1분마다 카운트다운 업데이트
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('선공개 리뷰', style: HwahaeTypography.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showPreviewInfoDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // 리뷰 목록 새로고침 - 실제로는 API 호출
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) setState(() {});
        },
        color: HwahaeColors.primary,
        child: CustomScrollView(
          slivers: [
            // 프로세스 안내 배너
            SliverToBoxAdapter(
              child: _buildProcessBanner(),
            ),
            // 선공개 리뷰 목록
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 예시 데이터 - 실제로는 API에서 가져옴
                  _buildPreviewReviewCard(
                    reviewId: '1',
                    reviewerName: '맛집탐험가',
                    reviewerGrade: 'senior',
                    totalScore: 4.2,
                    summary: '전체적으로 만족스러운 경험이었습니다. 다만 몇 가지 개선할 점이 있어요.',
                    submittedAt: DateTime.now().subtract(const Duration(hours: 24)),
                    hasResponse: false,
                  ),
                  const SizedBox(height: 12),
                  _buildPreviewReviewCard(
                    reviewId: '2',
                    reviewerName: '정직한리뷰어',
                    reviewerGrade: 'regular',
                    totalScore: 3.8,
                    summary: '가격 대비 괜찮았지만, 서비스 속도가 아쉬웠습니다.',
                    submittedAt: DateTime.now().subtract(const Duration(hours: 60)),
                    hasResponse: true,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HwahaeColors.primary.withOpacity(0.1),
            HwahaeColors.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HwahaeColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HwahaeColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.visibility_outlined,
                  color: HwahaeColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '72시간 선공개 시스템',
                  style: HwahaeTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 프로세스 단계
          _buildProcessSteps(),
        ],
      ),
    );
  }

  Widget _buildProcessSteps() {
    final steps = [
      _ProcessStep(
        number: 1,
        title: '리뷰 제출',
        description: '리뷰어가 리뷰 작성',
        icon: Icons.edit_note,
      ),
      _ProcessStep(
        number: 2,
        title: '선공개',
        description: '72시간 동안 미리 확인',
        icon: Icons.preview,
        isHighlighted: true,
      ),
      _ProcessStep(
        number: 3,
        title: '대응',
        description: '답변/이의제기 가능',
        icon: Icons.reply,
      ),
      _ProcessStep(
        number: 4,
        title: '자동 공개',
        description: '72시간 후 공개',
        icon: Icons.public,
      ),
    ];

    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: step.isHighlighted
                            ? HwahaeColors.primary
                            : HwahaeColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        step.icon,
                        size: 18,
                        color: step.isHighlighted
                            ? Colors.white
                            : HwahaeColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.title,
                      style: HwahaeTypography.captionMedium.copyWith(
                        fontWeight: step.isHighlighted
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: step.isHighlighted
                            ? HwahaeColors.primary
                            : HwahaeColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: HwahaeColors.textTertiary,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreviewReviewCard({
    required String reviewId,
    required String reviewerName,
    required String reviewerGrade,
    required double totalScore,
    required String summary,
    required DateTime submittedAt,
    required bool hasResponse,
  }) {
    final previewEndsAt = submittedAt.add(const Duration(hours: 72));
    final remaining = previewEndsAt.difference(DateTime.now());
    final isExpired = remaining.isNegative;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        border: Border.all(
          color: isExpired
              ? HwahaeColors.border
              : HwahaeColors.warning.withOpacity(0.3),
          width: isExpired ? 1 : 2,
        ),
        boxShadow: isExpired
            ? null
            : [
                BoxShadow(
                  color: HwahaeColors.warning.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카운트다운 헤더
          if (!isExpired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: HwahaeColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: HwahaeColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '공개까지 ',
                    style: HwahaeTypography.labelMedium.copyWith(
                      color: HwahaeColors.warning,
                    ),
                  ),
                  Text(
                    _formatRemainingTime(remaining),
                    style: HwahaeTypography.labelLarge.copyWith(
                      color: HwahaeColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (!hasResponse)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: HwahaeColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '답변 필요',
                        style: HwahaeTypography.captionSmall.copyWith(
                          color: HwahaeColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // 리뷰어 정보와 점수
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getGradeColor(reviewerGrade).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    reviewerName[0],
                    style: HwahaeTypography.titleMedium.copyWith(
                      color: _getGradeColor(reviewerGrade),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          reviewerName,
                          style: HwahaeTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getGradeColor(reviewerGrade).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getGradeLabel(reviewerGrade),
                            style: HwahaeTypography.captionSmall.copyWith(
                              color: _getGradeColor(reviewerGrade),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatSubmittedAt(submittedAt),
                      style: HwahaeTypography.captionMedium.copyWith(
                        color: HwahaeColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // 점수
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getScoreColor(totalScore).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: _getScoreColor(totalScore),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      totalScore.toStringAsFixed(1),
                      style: HwahaeTypography.titleMedium.copyWith(
                        color: _getScoreColor(totalScore),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 리뷰 요약
          Text(
            summary,
            style: HwahaeTypography.bodyMedium.copyWith(
              color: HwahaeColors.textSecondary,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),

          // 타임라인
          _buildReviewTimeline(submittedAt, hasResponse, previewEndsAt),

          const SizedBox(height: 16),

          // 액션 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showReviewDetailDialog(reviewId, reviewerName, totalScore, summary);
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('상세보기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HwahaeColors.primary,
                    side: const BorderSide(color: HwahaeColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasResponse
                      ? null
                      : () {
                          _showResponseDialog(reviewId);
                        },
                  icon: Icon(
                    hasResponse ? Icons.check : Icons.reply,
                    size: 18,
                  ),
                  label: Text(hasResponse ? '답변 완료' : '답변 작성'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HwahaeColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: HwahaeColors.success.withOpacity(0.1),
                    disabledForegroundColor: HwahaeColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 이의 제기 버튼
          if (!isExpired && !hasResponse) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                _showDisputeDialog(reviewId);
              },
              icon: Icon(
                Icons.flag_outlined,
                size: 16,
                color: HwahaeColors.error,
              ),
              label: Text(
                '이의 제기',
                style: HwahaeTypography.labelMedium.copyWith(
                  color: HwahaeColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewTimeline(
    DateTime submittedAt,
    bool hasResponse,
    DateTime previewEndsAt,
  ) {
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HwahaeColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTimelineItem(
            title: '리뷰 제출',
            date: submittedAt,
            isCompleted: true,
            isFirst: true,
          ),
          _buildTimelineItem(
            title: '선공개 시작',
            date: submittedAt,
            isCompleted: true,
          ),
          _buildTimelineItem(
            title: '업체 답변',
            date: hasResponse ? now : null,
            isCompleted: hasResponse,
            isPending: !hasResponse,
          ),
          _buildTimelineItem(
            title: '자동 공개',
            date: previewEndsAt,
            isCompleted: now.isAfter(previewEndsAt),
            isPending: now.isBefore(previewEndsAt),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    DateTime? date,
    bool isCompleted = false,
    bool isPending = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle
                    : isPending
                        ? Icons.radio_button_unchecked
                        : Icons.circle_outlined,
                size: 16,
                color: isCompleted
                    ? HwahaeColors.success
                    : isPending
                        ? HwahaeColors.warning
                        : HwahaeColors.textTertiary,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 20,
                  color: isCompleted
                      ? HwahaeColors.success.withOpacity(0.3)
                      : HwahaeColors.border,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: HwahaeTypography.captionMedium.copyWith(
                    color: isCompleted
                        ? HwahaeColors.textPrimary
                        : HwahaeColors.textTertiary,
                    fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (date != null)
                  Text(
                    _formatTimelineDate(date),
                    style: HwahaeTypography.captionSmall.copyWith(
                      color: HwahaeColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPreviewInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: HwahaeColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '선공개 시스템이란?',
              style: HwahaeTypography.titleMedium,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '리뷰가 공개되기 전 72시간 동안 업체에서 미리 확인하고 대응할 수 있는 시스템입니다.',
              style: HwahaeTypography.bodyMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.visibility,
              title: '미리 확인',
              description: '공개 전 리뷰 내용을 확인할 수 있어요.',
            ),
            _buildInfoItem(
              icon: Icons.reply,
              title: '답변 작성',
              description: '리뷰에 대한 답변과 개선 약속을 작성할 수 있어요.',
            ),
            _buildInfoItem(
              icon: Icons.flag,
              title: '이의 제기',
              description: '허위 사실이 있다면 이의를 제기할 수 있어요.',
            ),
            _buildInfoItem(
              icon: Icons.public,
              title: '자동 공개',
              description: '72시간 후 자동으로 공개됩니다.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '확인',
              style: HwahaeTypography.labelLarge.copyWith(
                color: HwahaeColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: HwahaeColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HwahaeTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: HwahaeTypography.captionMedium.copyWith(
                    color: HwahaeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDisputeDialog(String reviewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: HwahaeColors.error,
            ),
            const SizedBox(width: 8),
            Text(
              '이의 제기',
              style: HwahaeTypography.titleMedium,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이의 제기 시 운영팀에서 검토하며, 검토 기간 동안 리뷰 공개가 보류됩니다.',
              style: HwahaeTypography.bodyMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '이의 제기 사유를 작성해주세요...',
                hintStyle: HwahaeTypography.bodyMedium.copyWith(
                  color: HwahaeColors.textTertiary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: HwahaeColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: HwahaeColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '취소',
              style: HwahaeTypography.labelLarge.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // 이의 제기 API 호출
              try {
                // API 호출 시뮬레이션 - 실제로는 ApiClient를 통해 호출
                await Future.delayed(const Duration(milliseconds: 500));
              } catch (e) {
                // 에러 처리
              }
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('이의 제기가 접수되었습니다.'),
                  backgroundColor: HwahaeColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            child: Text(
              '제출',
              style: HwahaeTypography.labelLarge.copyWith(
                color: HwahaeColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDetailDialog(String reviewId, String reviewerName, double score, String summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 핸들바
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: HwahaeColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('리뷰 상세', style: HwahaeTypography.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // 컨텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 리뷰어 정보
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: HwahaeColors.primary.withOpacity(0.1),
                          child: Text(
                            reviewerName[0],
                            style: HwahaeTypography.titleSmall.copyWith(
                              color: HwahaeColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(reviewerName, style: HwahaeTypography.titleSmall),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 16, color: HwahaeColors.ratingStar),
                                  const SizedBox(width: 4),
                                  Text(
                                    score.toStringAsFixed(1),
                                    style: HwahaeTypography.labelMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 리뷰 요약
                    Text('리뷰 요약', style: HwahaeTypography.labelMedium.copyWith(
                      color: HwahaeColors.textSecondary,
                    )),
                    const SizedBox(height: 8),
                    Text(summary, style: HwahaeTypography.bodyMedium),
                    const SizedBox(height: 20),
                    // 상세 평가 (Mock)
                    Text('상세 평가', style: HwahaeTypography.labelMedium.copyWith(
                      color: HwahaeColors.textSecondary,
                    )),
                    const SizedBox(height: 12),
                    _buildDetailScoreItem('서비스', 4.5),
                    _buildDetailScoreItem('청결도', 4.0),
                    _buildDetailScoreItem('가격', 3.8),
                    _buildDetailScoreItem('품질', 4.2),
                    const SizedBox(height: 20),
                    // 장점
                    Text('장점', style: HwahaeTypography.labelMedium.copyWith(
                      color: HwahaeColors.success,
                    )),
                    const SizedBox(height: 8),
                    _buildBulletPoint('직원들이 친절하고 응대가 빨랐습니다'),
                    _buildBulletPoint('음식 맛이 좋고 양이 푸짐했습니다'),
                    const SizedBox(height: 16),
                    // 단점
                    Text('단점', style: HwahaeTypography.labelMedium.copyWith(
                      color: HwahaeColors.error,
                    )),
                    const SizedBox(height: 8),
                    _buildBulletPoint('대기 시간이 다소 길었습니다'),
                    _buildBulletPoint('주차 공간이 협소합니다'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailScoreItem(String label, double score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: HwahaeTypography.bodySmall),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: score / 5,
              backgroundColor: HwahaeColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(
                score >= 4 ? HwahaeColors.success :
                score >= 3 ? HwahaeColors.warning : HwahaeColors.error,
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            score.toStringAsFixed(1),
            style: HwahaeTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: HwahaeTypography.bodySmall)),
        ],
      ),
    );
  }

  void _showResponseDialog(String reviewId) {
    final responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.reply, color: HwahaeColors.primary),
            const SizedBox(width: 8),
            Text('답변 작성', style: HwahaeTypography.titleMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '리뷰어에게 전달할 답변을 작성해주세요. 작성된 답변은 리뷰와 함께 공개됩니다.',
              style: HwahaeTypography.bodySmall.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: responseController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: '답변을 입력해주세요...',
                hintStyle: HwahaeTypography.bodyMedium.copyWith(
                  color: HwahaeColors.textTertiary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: HwahaeColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: HwahaeColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '취소',
              style: HwahaeTypography.labelLarge.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (responseController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('답변 내용을 입력해주세요'),
                    backgroundColor: HwahaeColors.warning,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              // 답변 API 호출
              try {
                await Future.delayed(const Duration(milliseconds: 500));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('답변이 등록되었습니다'),
                    backgroundColor: HwahaeColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
                setState(() {});
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('답변 등록에 실패했습니다'),
                    backgroundColor: HwahaeColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            child: Text(
              '등록',
              style: HwahaeTypography.labelLarge.copyWith(
                color: HwahaeColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRemainingTime(Duration duration) {
    if (duration.isNegative) return '만료됨';

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours >= 24) {
      final days = hours ~/ 24;
      final remainingHours = hours % 24;
      return '$days일 $remainingHours시간';
    }

    return '$hours시간 $minutes분';
  }

  String _formatSubmittedAt(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inHours < 24) {
      return '${diff.inHours}시간 전 제출';
    }
    return '${diff.inDays}일 전 제출';
  }

  String _formatTimelineDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'master':
        return HwahaeColors.error;
      case 'senior':
        return HwahaeColors.warning;
      case 'regular':
        return HwahaeColors.primary;
      default:
        return HwahaeColors.textSecondary;
    }
  }

  String _getGradeLabel(String grade) {
    switch (grade) {
      case 'master':
        return '마스터';
      case 'senior':
        return '시니어';
      case 'regular':
        return '레귤러';
      default:
        return '루키';
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 4.5) return HwahaeColors.success;
    if (score >= 3.5) return HwahaeColors.warning;
    if (score >= 2.5) return HwahaeColors.accent;
    return HwahaeColors.error;
  }
}

class _ProcessStep {
  final int number;
  final String title;
  final String description;
  final IconData icon;
  final bool isHighlighted;

  _ProcessStep({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    this.isHighlighted = false,
  });
}
