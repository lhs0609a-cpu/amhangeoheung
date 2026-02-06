import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../../../shared/widgets/hwahae/hwahae_buttons.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../payment/data/models/payment_models.dart';
import '../../../payment/data/services/payment_service.dart';
import '../../../payment/presentation/screens/payment_screen.dart';

// 요금제 모델
class PricingPlan {
  final String id;
  final String name;
  final String description;
  final int monthlyPrice;
  final int yearlyPrice;
  final List<String> features;
  final List<String> highlights;
  final bool isPopular;
  final List<Color> gradientColors;

  const PricingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    this.highlights = const [],
    this.isPopular = false,
    this.gradientColors = const [HwahaeColors.primary, HwahaeColors.primaryLight],
  });

  int getPrice(bool isYearly) => isYearly ? yearlyPrice : monthlyPrice;
  int getSavedAmount() => (monthlyPrice * 12) - yearlyPrice;
}

// 요금제 데이터 (P1-1: 가치 재정의)
final pricingPlans = [
  const PricingPlan(
    id: 'free',
    name: '무료',
    description: '암행어흥을 시작하는 분들을 위한 플랜',
    monthlyPrice: 0,
    yearlyPrice: 0,
    features: [
      '월 3개 미션 신청 가능',
      '기본 리뷰어 배지',
      '일반 미션 알림',
      '기본 정산 (영업일 7일)',
    ],
    gradientColors: [Color(0xFF9CA3AF), Color(0xFF6B7280)],
  ),
  const PricingPlan(
    id: 'pro',
    name: 'Pro',
    description: '월 5회 이상 미션을 보장하는 프리미엄 플랜',
    monthlyPrice: 9900,
    yearlyPrice: 99000,
    isPopular: true,
    features: [
      '월 최소 5개 미션 보장 (미달 시 차액 환불)',
      '인기 미션 30분 우선 알림',
      '골드 리뷰어 배지 (선정률 +20%)',
      '빠른 정산 (영업일 3일)',
      '전용 1:1 채팅 지원',
      '미션 통계 및 수입 대시보드',
    ],
    highlights: ['가장 인기', '미션 보장'],
    gradientColors: HwahaeColors.gradientPrimary,
  ),
  const PricingPlan(
    id: 'enterprise',
    name: 'Enterprise',
    description: '원하는 미션 100% 배정을 보장하는 VIP 플랜',
    monthlyPrice: 29900,
    yearlyPrice: 299000,
    features: [
      'Pro 플랜의 모든 기능 포함',
      '원하는 미션 100% 배정 보장',
      '다이아몬드 리뷰어 배지 (최상위 신뢰도)',
      '즉시 정산 (당일, 영업일 기준)',
      '전담 VIP 매니저 배정',
      '맞춤형 리뷰 품질 컨설팅',
      'API 연동 및 데이터 내보내기',
    ],
    highlights: ['100% 배정 보장'],
    gradientColors: HwahaeColors.gradientAccent,
  ),
];

// 기능 비교 데이터
class FeatureComparison {
  final String feature;
  final String free;
  final String pro;
  final String enterprise;

  const FeatureComparison({
    required this.feature,
    required this.free,
    required this.pro,
    required this.enterprise,
  });
}

// P1-1: 기능 비교 (가치 명확화)
final featureComparisons = [
  const FeatureComparison(
    feature: '월 미션 보장',
    free: '신청만 가능',
    pro: '최소 5회 보장',
    enterprise: '100% 배정',
  ),
  const FeatureComparison(
    feature: '미션 알림',
    free: '일반',
    pro: '30분 우선',
    enterprise: '즉시 + 독점',
  ),
  const FeatureComparison(
    feature: '정산 소요',
    free: '7영업일',
    pro: '3영업일',
    enterprise: '당일',
  ),
  const FeatureComparison(
    feature: '선정률 보너스',
    free: '-',
    pro: '+20%',
    enterprise: '+50%',
  ),
  const FeatureComparison(
    feature: '리뷰어 배지',
    free: '기본',
    pro: '골드',
    enterprise: '다이아몬드',
  ),
  const FeatureComparison(
    feature: '고객 지원',
    free: 'FAQ',
    pro: '1:1 채팅',
    enterprise: '전담 매니저',
  ),
  const FeatureComparison(
    feature: '통계/대시보드',
    free: '-',
    pro: 'O',
    enterprise: '고급 분석',
  ),
  const FeatureComparison(
    feature: '미달 시 보상',
    free: '-',
    pro: '차액 환불',
    enterprise: '전액 환불',
  ),
];

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen>
    with SingleTickerProviderStateMixin {
  bool _isYearly = true;
  int _selectedPlanIndex = 1; // Pro 플랜 기본 선택
  bool _isProcessingPayment = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      body: CustomScrollView(
        slivers: [
          // 헤더
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: HwahaeColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: HwahaeColors.gradientPrimary,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '암행어흥 Premium',
                        style: HwahaeTypography.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '더 많은 미션, 더 빠른 정산, 더 높은 수익',
                        style: HwahaeTypography.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 결제 주기 선택
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildBillingToggle(),
            ),
          ),

          // 탭
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '요금제'),
                  Tab(text: '기능 비교'),
                ],
                labelColor: HwahaeColors.primary,
                unselectedLabelColor: HwahaeColors.textSecondary,
                indicatorColor: HwahaeColors.primary,
                indicatorWeight: 3,
              ),
            ),
          ),

          // 탭 콘텐츠
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 요금제 탭
                _buildPricingCardsTab(),
                // 기능 비교 탭
                _buildComparisonTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomCTA(),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: HwahaeColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isYearly ? HwahaeColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_isYearly ? HwahaeTheme.shadowSM : null,
                ),
                child: Text(
                  '월간 결제',
                  textAlign: TextAlign.center,
                  style: HwahaeTypography.labelLarge.copyWith(
                    color: !_isYearly
                        ? HwahaeColors.textPrimary
                        : HwahaeColors.textSecondary,
                    fontWeight: !_isYearly ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isYearly ? HwahaeColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _isYearly ? HwahaeTheme.shadowSM : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '연간 결제',
                      style: HwahaeTypography.labelLarge.copyWith(
                        color: _isYearly
                            ? HwahaeColors.textPrimary
                            : HwahaeColors.textSecondary,
                        fontWeight: _isYearly ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: HwahaeColors.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '17% 할인',
                        style: HwahaeTypography.badge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...pricingPlans.asMap().entries.map((entry) {
            final index = entry.key;
            final plan = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPricingCard(plan, index),
            );
          }).toList(),
          const SizedBox(height: 24),
          _buildGuaranteeSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPricingCard(PricingPlan plan, int index) {
    final isSelected = _selectedPlanIndex == index;
    final price = plan.getPrice(_isYearly);

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
          border: Border.all(
            color: isSelected ? HwahaeColors.primary : HwahaeColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? HwahaeTheme.shadowMD : HwahaeTheme.shadowSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                // 플랜 아이콘
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: plan.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getPlanIcon(plan.id),
                    color: Colors.white,
                    size: 24,
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
                            plan.name,
                            style: HwahaeTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (plan.isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: HwahaeColors.gradientAccent,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '인기',
                                style: HwahaeTypography.badge.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.description,
                        style: HwahaeTypography.captionMedium,
                      ),
                    ],
                  ),
                ),
                // 선택 표시
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? HwahaeColors.primary
                        : HwahaeColors.surfaceVariant,
                    border: Border.all(
                      color: isSelected
                          ? HwahaeColors.primary
                          : HwahaeColors.border,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 가격
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (price == 0)
                  Text(
                    '무료',
                    style: HwahaeTypography.headlineLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: plan.gradientColors[0],
                    ),
                  )
                else ...[
                  Text(
                    '${_formatCurrency(price)}',
                    style: HwahaeTypography.headlineLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: plan.gradientColors[0],
                    ),
                  ),
                  Text(
                    '원',
                    style: HwahaeTypography.titleMedium.copyWith(
                      color: plan.gradientColors[0],
                    ),
                  ),
                  Text(
                    _isYearly ? '/년' : '/월',
                    style: HwahaeTypography.bodyMedium.copyWith(
                      color: HwahaeColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            if (_isYearly && plan.monthlyPrice > 0) ...[
              const SizedBox(height: 4),
              Text(
                '월 ${_formatCurrency(plan.yearlyPrice ~/ 12)}원 (${_formatCurrency(plan.getSavedAmount())}원 절약)',
                style: HwahaeTypography.captionMedium.copyWith(
                  color: HwahaeColors.success,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // 구분선
            const Divider(height: 1),
            const SizedBox(height: 16),

            // 기능 목록
            ...plan.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: plan.gradientColors[0].withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          size: 12,
                          color: plan.gradientColors[0],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feature,
                          style: HwahaeTypography.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 플랜 헤더
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: HwahaeColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(color: HwahaeColors.border),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text('기능'),
                  ),
                ),
                ...['무료', 'Pro', 'Enterprise'].map((name) => Expanded(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: HwahaeTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: name == 'Pro'
                              ? HwahaeColors.primary
                              : HwahaeColors.textPrimary,
                        ),
                      ),
                    )),
              ],
            ),
          ),

          // 비교 행들
          ...featureComparisons.asMap().entries.map((entry) {
            final index = entry.key;
            final comparison = entry.value;
            final isLast = index == featureComparisons.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: index.isEven
                    ? HwahaeColors.surface
                    : HwahaeColors.surfaceVariant,
                border: Border(
                  left: const BorderSide(color: HwahaeColors.border),
                  right: const BorderSide(color: HwahaeColors.border),
                  bottom: BorderSide(
                    color: HwahaeColors.border,
                    width: isLast ? 1 : 0,
                  ),
                ),
                borderRadius: isLast
                    ? const BorderRadius.vertical(bottom: Radius.circular(16))
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      comparison.feature,
                      style: HwahaeTypography.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: _buildComparisonValue(comparison.free),
                  ),
                  Expanded(
                    child: _buildComparisonValue(comparison.pro, isPro: true),
                  ),
                  Expanded(
                    child: _buildComparisonValue(comparison.enterprise),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          _buildGuaranteeSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildComparisonValue(String value, {bool isPro = false}) {
    if (value == 'O') {
      return Icon(
        Icons.check_circle,
        color: isPro ? HwahaeColors.primary : HwahaeColors.success,
        size: 20,
      );
    }
    if (value == '-') {
      return Icon(
        Icons.remove_circle_outline,
        color: HwahaeColors.textTertiary,
        size: 20,
      );
    }
    return Text(
      value,
      textAlign: TextAlign.center,
      style: HwahaeTypography.captionMedium.copyWith(
        color: isPro ? HwahaeColors.primary : null,
        fontWeight: isPro ? FontWeight.w600 : null,
      ),
    );
  }

  Widget _buildGuaranteeSection() {
    return Column(
      children: [
        // 미션 보장제 안내
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                HwahaeColors.primary.withOpacity(0.1),
                HwahaeColors.primaryLight.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
            border: Border.all(color: HwahaeColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified, color: HwahaeColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '미션 보장제',
                    style: HwahaeTypography.titleMedium.copyWith(
                      color: HwahaeColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildGuaranteeItem(
                'Pro 플랜',
                '월 5회 미션 미달 시 차액 환불',
              ),
              const SizedBox(height: 8),
              _buildGuaranteeItem(
                'Enterprise 플랜',
                '원하는 미션 100% 배정 또는 전액 환불',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 7일 무료 체험
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: HwahaeColors.successLight,
            borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.card_giftcard, color: HwahaeColors.success),
                  const SizedBox(width: 8),
                  Text(
                    '7일 무료 체험',
                    style: HwahaeTypography.titleMedium.copyWith(
                      color: HwahaeColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '모든 유료 플랜은 7일 무료 체험이 가능합니다.\n마음에 들지 않으면 언제든 취소하세요.',
                textAlign: TextAlign.center,
                style: HwahaeTypography.bodySmall.copyWith(
                  color: HwahaeColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuaranteeItem(String plan, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: HwahaeColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            plan,
            style: HwahaeTypography.badge.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            description,
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCTA() {
    final selectedPlan = pricingPlans[_selectedPlanIndex];
    final price = selectedPlan.getPrice(_isYearly);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HwahaeColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${selectedPlan.name} 플랜',
                    style: HwahaeTypography.labelMedium.copyWith(
                      color: HwahaeColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (price == 0)
                    Text(
                      '무료',
                      style: HwahaeTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    Text(
                      '${_formatCurrency(price)}원${_isYearly ? '/년' : '/월'}',
                      style: HwahaeTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: HwahaePrimaryButton(
                text: price == 0 ? '현재 플랜' : '구독 시작하기',
                onPressed: price == 0 ? null : () => _showPaymentSheet(selectedPlan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentSheet(PricingPlan plan) {
    final price = plan.getPrice(_isYearly);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들바
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: HwahaeColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // 플랜 정보
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: plan.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    _getPlanIcon(plan.id),
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${plan.name} 플랜',
                          style: HwahaeTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _isYearly ? '연간 구독' : '월간 구독',
                          style: HwahaeTypography.captionMedium.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_formatCurrency(price)}원',
                        style: HwahaeTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _isYearly ? '/년' : '/월',
                        style: HwahaeTypography.captionSmall.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 결제 방법
            Text(
              '결제 방법 선택',
              style: HwahaeTypography.titleSmall,
            ),
            const SizedBox(height: 16),

            _buildPaymentOption(
              icon: Icons.credit_card,
              title: '신용/체크카드',
              subtitle: '카드 결제',
              onTap: () => _processPayment('card', plan),
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              icon: Icons.phone_android,
              title: '카카오페이',
              subtitle: '간편 결제',
              color: const Color(0xFFFEE500),
              iconColor: const Color(0xFF3C1E1E),
              onTap: () => _processPayment('kakaopay', plan),
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              icon: Icons.apple,
              title: 'Apple Pay',
              subtitle: '간편 결제',
              color: Colors.black,
              iconColor: Colors.white,
              onTap: () => _processPayment('apple', plan),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HwahaeColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: HwahaeColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color ?? HwahaeColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: HwahaeTypography.labelLarge,
                  ),
                  Text(
                    subtitle,
                    style: HwahaeTypography.captionMedium,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: HwahaeColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(String method, PricingPlan plan) async {
    if (_isProcessingPayment) return;
    setState(() => _isProcessingPayment = true);

    Navigator.pop(context); // 결제 방법 선택 시트 닫기

    // 결제 수단 매핑
    final paymentMethod = switch (method) {
      'card' => PaymentMethod.card,
      'kakaopay' => PaymentMethod.kakaoPay,
      'apple' => PaymentMethod.applePay,
      _ => PaymentMethod.card,
    };

    final price = plan.getPrice(_isYearly);
    final paymentService = PaymentService();

    // 로그인된 사용자 정보 가져오기
    String customerName = '암행어흥 사용자';
    String customerEmail = 'user@amhangeoheung.com';
    try {
      final storage = const FlutterSecureStorage();
      final name = await storage.read(key: 'user_name');
      final email = await storage.read(key: 'user_email');
      if (name != null) customerName = name;
      if (email != null) customerEmail = email;
    } catch (_) {}

    // 결제 요청 데이터 생성
    final request = PaymentRequest(
      orderId: paymentService.generateOrderId(),
      orderName: '암행어흥 ${plan.name} 플랜 (${_isYearly ? '연간' : '월간'})',
      amount: price,
      customerName: customerName,
      customerEmail: customerEmail,
      method: paymentMethod,
      isSubscription: true,
    );

    // 결제 화면 띄우기
    final result = await showPaymentScreen(
      context: context,
      request: request,
    );

    if (!mounted) return;

    if (result != null && result.success) {
      // 결제 성공
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('${plan.name} 플랜 구독이 완료되었습니다!'),
            ],
          ),
          backgroundColor: HwahaeColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

      Navigator.pop(context); // 요금제 화면 닫기
    } else if (result != null) {
      // 결제 실패
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.errorMessage ?? '결제에 실패했습니다',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: HwahaeColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }

    if (mounted) setState(() => _isProcessingPayment = false);
  }

  IconData _getPlanIcon(String planId) {
    switch (planId) {
      case 'free':
        return Icons.person_outline;
      case 'pro':
        return Icons.workspace_premium;
      case 'enterprise':
        return Icons.diamond;
      default:
        return Icons.star;
    }
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: HwahaeColors.surface,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
