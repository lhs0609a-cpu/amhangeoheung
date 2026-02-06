import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../../../shared/widgets/skeleton_widgets.dart';

/// 무료 신뢰도 분석 체험 화면
/// Value-First 온보딩: 가입 전에 서비스 가치를 먼저 경험
class FreeTrialScreen extends ConsumerStatefulWidget {
  const FreeTrialScreen({super.key});

  @override
  ConsumerState<FreeTrialScreen> createState() => _FreeTrialScreenState();
}

class _FreeTrialScreenState extends ConsumerState<FreeTrialScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  bool _hasSearched = false;
  _FreeTrialResult? _result;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _errorMessage;

  Future<void> _searchBusiness() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _result = null;
      _errorMessage = null;
    });

    try {
      final apiClient = ApiClient();
      final response = await apiClient.get(
        '/trust-preview',
        queryParameters: {'query': query},
      );

      if (!mounted) return;

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data['found'] == true) {
          setState(() {
            _isSearching = false;
            _result = _FreeTrialResult(
              businessName: data['businessName'] ?? query,
              trustScore: data['trustScore'] ?? 0,
              reviewCount: data['reviewCount'] ?? 0,
              avgRating: (data['avgRating'] ?? 0).toDouble(),
              categoryRank: data['categoryRank'] ?? 0,
              totalInCategory: data['totalInCategory'] ?? 0,
              strengths: List<String>.from(data['strengths'] ?? []),
              improvements: List<String>.from(data['improvements'] ?? []),
            );
          });
        } else {
          setState(() {
            _isSearching = false;
            _result = null;
          });
        }
      } else {
        setState(() {
          _isSearching = false;
          _errorMessage = response.data['message'] ?? '분석에 실패했습니다';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = '네트워크 오류가 발생했습니다. 다시 시도해주세요.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: HwahaeColors.textPrimary),
          onPressed: () => context.go('/onboarding'),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text(
              '로그인',
              style: HwahaeTypography.labelLarge.copyWith(
                color: HwahaeColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              _buildHeader(),
              const SizedBox(height: 24),

              // 검색 입력
              _buildSearchInput(),
              const SizedBox(height: 24),

              // 결과 또는 안내
              if (_isSearching)
                _buildLoadingState()
              else if (_errorMessage != null)
                _buildErrorState()
              else if (_result != null)
                _buildResultCard(_result!)
              else if (_hasSearched)
                _buildNoResultState()
              else
                _buildGuideSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: HwahaeColors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: HwahaeColors.primary),
              const SizedBox(width: 4),
              Text(
                '무료 체험',
                style: HwahaeTypography.labelSmall.copyWith(
                  color: HwahaeColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '우리 가게 신뢰도\n무료로 분석해보세요',
          style: HwahaeTypography.headlineLarge.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '가입 없이 바로 업체의 리뷰 신뢰도를 확인할 수 있어요',
          style: HwahaeTypography.bodyMedium.copyWith(
            color: HwahaeColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        border: Border.all(color: HwahaeColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '업체명을 입력하세요 (예: 맛있는 식당)',
              hintStyle: HwahaeTypography.bodyMedium.copyWith(
                color: HwahaeColors.textTertiary,
              ),
              prefixIcon: const Icon(Icons.search, color: HwahaeColors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            onSubmitted: (_) => _searchBusiness(),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ElevatedButton(
              onPressed: _isSearching ? null : _searchBusiness,
              style: ElevatedButton.styleFrom(
                backgroundColor: HwahaeColors.primary,
                foregroundColor: HwahaeColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                ),
                elevation: 0,
              ),
              child: Text(
                _isSearching ? '분석 중...' : '무료 분석하기',
                style: HwahaeTypography.labelLarge.copyWith(
                  color: HwahaeColors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: HwahaeColors.surface,
            borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
            border: Border.all(color: HwahaeColors.border),
          ),
          child: Column(
            children: [
              const CircularProgressIndicator(
                color: HwahaeColors.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                '리뷰 데이터를 분석하고 있어요',
                style: HwahaeTypography.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '잠시만 기다려주세요...',
                style: HwahaeTypography.bodySmall.copyWith(
                  color: HwahaeColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              // 분석 중인 항목들
              _buildAnalyzingItem('리뷰 진위 검증', true),
              _buildAnalyzingItem('패턴 분석', true),
              _buildAnalyzingItem('신뢰도 계산', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingItem(String label, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (completed)
            const Icon(Icons.check_circle, size: 20, color: HwahaeColors.success)
          else
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: HwahaeColors.primary,
              ),
            ),
          const SizedBox(width: 12),
          Text(
            label,
            style: HwahaeTypography.bodyMedium.copyWith(
              color: completed ? HwahaeColors.textSecondary : HwahaeColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(_FreeTrialResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 결과 헤더
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [HwahaeColors.primary, HwahaeColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.verified, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.businessName,
                      style: HwahaeTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 신뢰도 점수
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${result.trustScore}',
                    style: HwahaeTypography.displayLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 72,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '점',
                        style: HwahaeTypography.titleLarge.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        '/ 100',
                        style: HwahaeTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getTrustLevel(result.trustScore),
                  style: HwahaeTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 기본 정보
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HwahaeColors.surface,
            borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
            border: Border.all(color: HwahaeColors.border),
          ),
          child: Row(
            children: [
              _buildStatItem('리뷰 수', '${result.reviewCount}개'),
              _buildDivider(),
              _buildStatItem('평균 평점', '${result.avgRating}점'),
              _buildDivider(),
              _buildStatItem('카테고리 순위', '${result.categoryRank}위'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 강점
        _buildAnalysisSection(
          '강점',
          Icons.thumb_up,
          HwahaeColors.success,
          result.strengths,
        ),
        const SizedBox(height: 12),

        // 개선점
        _buildAnalysisSection(
          '개선 포인트',
          Icons.lightbulb_outline,
          HwahaeColors.warning,
          result.improvements,
        ),
        const SizedBox(height: 24),

        // 블러 처리된 상세 분석 (가입 유도)
        _buildLockedSection(),
        const SizedBox(height: 24),

        // CTA
        _buildCTASection(),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: HwahaeTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
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

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: HwahaeColors.divider,
    );
  }

  Widget _buildAnalysisSection(
    String title,
    IconData icon,
    Color color,
    List<String> items,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        border: Border.all(color: HwahaeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: HwahaeTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: HwahaeTypography.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLockedSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HwahaeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
        border: Border.all(color: HwahaeColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.lock_outline,
            size: 48,
            color: HwahaeColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            '상세 분석 보고서',
            style: HwahaeTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '가입하면 경쟁업체 비교, 리뷰 트렌드 분석,\nROI 예측 등 상세 보고서를 볼 수 있어요',
            textAlign: TextAlign.center,
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          // 상세 기능 미리보기 (블러)
          Stack(
            children: [
              Opacity(
                opacity: 0.3,
                child: Column(
                  children: [
                    const SkeletonLine(height: 14),
                    const SizedBox(height: 8),
                    const SkeletonLine(height: 14),
                    const SizedBox(height: 8),
                    const SkeletonLine(width: 200, height: 14),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HwahaeColors.primary,
              foregroundColor: HwahaeColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add_outlined),
                const SizedBox(width: 8),
                Text(
                  '무료로 가입하고 상세 보기',
                  style: HwahaeTypography.labelLarge.copyWith(
                    color: HwahaeColors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            setState(() {
              _result = null;
              _hasSearched = false;
              _searchController.clear();
            });
          },
          child: Text(
            '다른 업체 분석하기',
            style: HwahaeTypography.labelMedium.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
        border: Border.all(color: HwahaeColors.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: HwahaeColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            '오류가 발생했습니다',
            style: HwahaeTypography.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '다시 시도해주세요',
            textAlign: TextAlign.center,
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _searchBusiness,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
        border: Border.all(color: HwahaeColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: HwahaeColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            '검색 결과가 없습니다',
            style: HwahaeTypography.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '다른 키워드로 검색해보세요',
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '암행어흥이 분석하는 것들',
          style: HwahaeTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          Icons.verified_user,
          '리뷰 진위 검증',
          '실제 방문자의 리뷰인지 AI가 분석해요',
        ),
        _buildFeatureItem(
          Icons.analytics_outlined,
          '패턴 분석',
          '이상한 리뷰 패턴을 자동으로 감지해요',
        ),
        _buildFeatureItem(
          Icons.compare_arrows,
          '경쟁 분석',
          '같은 카테고리 업체와 비교 분석해요',
        ),
        _buildFeatureItem(
          Icons.trending_up,
          'ROI 예측',
          '신뢰도 개선 시 매출 증가를 예측해요',
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: HwahaeColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: HwahaeColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HwahaeTypography.titleSmall,
                ),
                Text(
                  description,
                  style: HwahaeTypography.bodySmall.copyWith(
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

  String _getTrustLevel(int score) {
    if (score >= 90) return '매우 신뢰할 수 있는 업체';
    if (score >= 80) return '신뢰할 수 있는 업체';
    if (score >= 70) return '보통 수준의 신뢰도';
    if (score >= 60) return '개선이 필요한 신뢰도';
    return '신뢰도 관리가 필요해요';
  }
}

class _FreeTrialResult {
  final String businessName;
  final int trustScore;
  final int reviewCount;
  final double avgRating;
  final int categoryRank;
  final int totalInCategory;
  final List<String> strengths;
  final List<String> improvements;

  _FreeTrialResult({
    required this.businessName,
    required this.trustScore,
    required this.reviewCount,
    required this.avgRating,
    required this.categoryRank,
    required this.totalInCategory,
    required this.strengths,
    required this.improvements,
  });
}
