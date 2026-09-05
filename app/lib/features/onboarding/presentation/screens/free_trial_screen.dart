import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';

/// 무료 신뢰도 분석 체험 화면
/// Value-First 온보딩: 가입 전에 서비스 가치를 먼저 경험
///
/// 점수는 서버(`/trust-preview`)가 계산한 값을 그대로 보여준다. 예전에는
/// 이 화면이 리뷰 수와 평점만 가지고 자체 공식으로 점수를 만들어 냈다.
/// 가입 전에 본 점수와 가입 후에 보는 점수가 다르면, 하필 신뢰를 파는
/// 제품에서 첫 숫자가 거짓이 된다.
class FreeTrialScreen extends ConsumerStatefulWidget {
  const FreeTrialScreen({super.key});

  @override
  ConsumerState<FreeTrialScreen> createState() => _FreeTrialScreenState();
}

class _FreeTrialResult {
  const _FreeTrialResult({
    required this.businessName,
    required this.trustScore,
    required this.reviewCount,
    required this.avgRating,
    required this.categoryRank,
    required this.totalInCategory,
    required this.strengths,
    required this.improvements,
  });

  final String businessName;
  final int trustScore;
  final int reviewCount;
  final double avgRating;
  final int categoryRank;
  final int totalInCategory;
  final List<String> strengths;
  final List<String> improvements;

  factory _FreeTrialResult.fromJson(Map<String, dynamic> json) {
    return _FreeTrialResult(
      businessName: json['businessName'] ?? '',
      trustScore: (json['trustScore'] as num?)?.round() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
      categoryRank: (json['categoryRank'] as num?)?.toInt() ?? 0,
      totalInCategory: (json['totalInCategory'] as num?)?.toInt() ?? 0,
      strengths: (json['strengths'] as List?)?.cast<String>() ?? const [],
      improvements: (json['improvements'] as List?)?.cast<String>() ?? const [],
    );
  }
}

class _FreeTrialScreenState extends ConsumerState<FreeTrialScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _error;
  _FreeTrialResult? _result;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchBusiness() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      AppToast.warning(context, '업체명을 두 글자 이상 입력해주세요');
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _error = null;
    });

    try {
      final response = await ApiClient().get(
        '/trust-preview',
        queryParameters: {'query': query},
      );
      if (!mounted) return;

      final data = response.data['data'] as Map<String, dynamic>?;
      setState(() {
        _isSearching = false;
        _result = (data != null && data['found'] == true)
            ? _FreeTrialResult.fromJson(data)
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _result = null;
        // 검색 결과 없음과 통신 실패를 구분한다. 예전에는 둘 다
        // "검색 결과가 없습니다"로 보여서, 서버가 죽어도 가게가 없는
        // 것처럼 읽혔다.
        _error = ApiClient.extractErrorMessage(e) ?? '분석에 실패했습니다';
      });
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _hasSearched = false;
      _error = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: '무료 신뢰도 분석',
      // /try-free 는 push 로도 go 로도 들어온다. 스택이 없을 때 뒤로가기가
      // 사라지면 로그인 말고는 나갈 길이 없어진다.
      showBack: true,
      onBack: () => context.go('/onboarding'),
      actions: [
        AppButton.ghost(
          label: '로그인',
          size: AppButtonSize.small,
          onPressed: () => context.go('/login'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '우리 가게 신뢰도\n무료로 확인해보세요',
            style: HwahaeTypography.headlineLarge.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '가입 없이 바로 확인할 수 있어요',
            style: HwahaeTypography.bodyMedium.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: _searchController,
            hint: '업체명을 입력하세요',
            prefixIcon: Icons.search_rounded,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _searchBusiness(),
          ),
          const SizedBox(height: 10),
          AppButton(
            label: '무료로 분석하기',
            isLoading: _isSearching,
            onPressed: _isSearching ? null : _searchBusiness,
          ),
          const SizedBox(height: 24),
          if (_isSearching)
            const _Analyzing()
          else if (_result != null)
            _ResultView(result: _result!, onReset: _reset)
          else if (_error != null)
            AppErrorState.fromMessage(_error!, onRetry: _searchBusiness)
          else if (_hasSearched)
            const AppEmptyState(
              icon: Icons.search_off_rounded,
              title: '그 이름으로는 못 찾겠네',
              message: '아직 암행어흥에 등록되지 않은 가게일 수 있어',
            )
          else
            const _GuideSection(),
          const AppBottomSpacer.plain(),
        ],
      ),
    );
  }
}

class _Analyzing extends StatelessWidget {
  const _Analyzing();

  @override
  Widget build(BuildContext context) {
    // 예전에는 "리뷰 진위 검증 ✓ / 패턴 분석 ✓ / 신뢰도 계산 …" 이라고
    // 단계별 체크가 켜졌는데, 전부 하드코딩된 그림이었다. 실제로는 요청
    // 한 번이다. 진행하지 않은 일을 진행한 것처럼 보이면 안 된다.
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: HwahaeColors.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 18),
          Text('리뷰를 살펴보는 중', style: HwahaeTypography.titleMedium),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result, required this.onReset});

  final _FreeTrialResult result;
  final VoidCallback onReset;

  Color get _scoreColor {
    if (result.trustScore >= 75) return HwahaeColors.accent;
    if (result.trustScore >= 45) return HwahaeColors.warning;
    return HwahaeColors.secondary;
  }

  String get _level {
    final s = result.trustScore;
    if (s >= 90) return '매우 신뢰할 수 있는 가게';
    if (s >= 80) return '신뢰할 수 있는 가게';
    if (s >= 70) return '보통 수준';
    if (s >= 60) return '개선이 필요합니다';
    return '신뢰도 관리가 필요합니다';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Text(
                result.businessName,
                style: HwahaeTypography.titleLarge,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${result.trustScore}',
                    style: HwahaeTypography.displayLarge.copyWith(
                      color: _scoreColor,
                      fontSize: 68,
                      height: 1.05,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 4),
                    child: Text(
                      '/ 100',
                      style: HwahaeTypography.titleMedium.copyWith(
                        color: HwahaeColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppBadge(label: _level, color: _scoreColor),
            ],
          ),
        ),
        const SizedBox(height: AppLayout.cardGap),
        AppCard(
          style: AppCardStyle.outlined,
          child: Row(
            children: [
              _Stat(label: '리뷰 수', value: '${result.reviewCount}개'),
              const _StatDivider(),
              _Stat(
                label: '평균 평점',
                value: '${result.avgRating.toStringAsFixed(1)}점',
              ),
              const _StatDivider(),
              _Stat(
                label: '업종 순위',
                // 분모가 없으면 "12위"가 좋은 건지 나쁜 건지 알 수 없다.
                // 서버가 보내주는 값을 받아만 두고 안 쓰고 있었다.
                value: result.totalInCategory > 0
                    ? '${result.categoryRank}/${result.totalInCategory}'
                    : '${result.categoryRank}위',
              ),
            ],
          ),
        ),
        if (result.strengths.isNotEmpty) ...[
          const SizedBox(height: AppLayout.cardGap),
          _AnalysisSection(
            title: '강점',
            icon: Icons.check_circle_rounded,
            color: HwahaeColors.accent,
            items: result.strengths,
          ),
        ],
        if (result.improvements.isNotEmpty) ...[
          const SizedBox(height: AppLayout.cardGap),
          _AnalysisSection(
            title: '개선 포인트',
            icon: Icons.error_outline_rounded,
            color: HwahaeColors.secondary,
            items: result.improvements,
          ),
        ],
        const SizedBox(height: AppLayout.sectionGap),
        const _LockedSection(),
        const SizedBox(height: AppLayout.sectionGap),
        AppButton(
          label: '무료로 가입하고 감찰 요청하기',
          icon: Icons.person_add_outlined,
          size: AppButtonSize.large,
          onPressed: () => context.go('/register'),
        ),
        const SizedBox(height: 6),
        AppButton.ghost(label: '다른 업체 분석하기', onPressed: onReset),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: HwahaeTypography.titleMedium),
          const SizedBox(height: 4),
          Text(
            label,
            style: HwahaeTypography.captionMedium.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 38, color: HwahaeColors.divider);
  }
}

class _AnalysisSection extends StatelessWidget {
  const _AnalysisSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      style: AppCardStyle.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(title, style: HwahaeTypography.titleSmall),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Icon(Icons.circle, size: 5, color: color),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: HwahaeTypography.bodySmall.copyWith(
                        color: HwahaeColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LockedSection extends StatelessWidget {
  const _LockedSection();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      style: AppCardStyle.sunken,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 40,
            color: HwahaeColors.textTertiary,
          ),
          const SizedBox(height: 10),
          Text('가입하면 볼 수 있는 것', style: HwahaeTypography.titleMedium),
          const SizedBox(height: 10),
          // 여기서 약속하는 것은 전부 실제로 있는 기능이어야 한다.
          // 예전에는 "ROI 예측"을 걸어뒀는데, 그 기능은 가상 매출을
          // 지어낸다는 이유로 이미 제거된 것이다.
          for (final line in const [
            '감찰관이 남긴 지적 항목 전체',
            '지적을 고쳤는지 다음 감찰에서 추적',
            '리뷰 공개 전 72시간 선공개',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: HwahaeColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: HwahaeTypography.bodySmall.copyWith(
                        color: HwahaeColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          AppButton.outline(
            label: '가입하고 상세 분석 보기',
            icon: Icons.lock_open_rounded,
            onPressed: () => context.go('/register'),
          ),
        ],
      ),
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection();

  @override
  Widget build(BuildContext context) {
    // 실제로 하는 일만 적는다. "AI 가 분석한다"고 써 있었지만 검증은
    // GPS 체류 확인 · 영수증 OCR · 담합 감지 규칙이다.
    const items = <({IconData icon, String title, String description})>[
      (
        icon: Icons.location_on_outlined,
        title: '진짜 방문했는지 확인',
        description: 'GPS 로 매장 안에 머문 시간을 확인합니다',
      ),
      (
        icon: Icons.receipt_long_outlined,
        title: '영수증 확인',
        description: '영수증을 읽어 결제 사실과 대조합니다',
      ),
      (
        icon: Icons.groups_outlined,
        title: '담합 감지',
        description: '같은 업체와 감찰관이 반복해서 엮이지 않게 막습니다',
      ),
      (
        icon: Icons.fact_check_outlined,
        title: '지적 추적',
        description: '지적한 것이 다음 감찰에서 고쳐졌는지 따라갑니다',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('암행어흥이 확인하는 것들', style: HwahaeTypography.titleMedium),
        const SizedBox(height: 14),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: HwahaeColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    color: HwahaeColors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: HwahaeTypography.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: HwahaeTypography.bodySmall.copyWith(
                          color: HwahaeColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
