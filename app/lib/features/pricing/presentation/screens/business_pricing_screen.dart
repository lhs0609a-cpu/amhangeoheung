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

class BusinessPricingPlan {
  final String id;
  final String name;
  final String description;
  final int monthlyPrice;
  final int yearlyPrice;
  final List<String> features;
  final List<String> highlights;
  final bool isPopular;
  final List<Color> gradientColors;

  const BusinessPricingPlan({
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

final businessPricingPlans = [
  const BusinessPricingPlan(
    id: 'starter',
    name: 'Starter',
    description: '소규모 매장을 위한 시작 플랜',
    monthlyPrice: 99000,
    yearlyPrice: 990000,
    features: [
      '월 1회 미스터리 쇼핑',
      '기본 리포트 제공',
      '브론즈 신뢰 배지',
      '기본 리뷰 관리',
    ],
    gradientColors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
  ),
  const BusinessPricingPlan(
    id: 'growth',
    name: 'Growth',
    description: '성장하는 매장을 위한 인기 플랜',
    monthlyPrice: 199000,
    yearlyPrice: 1990000,
    isPopular: true,
    features: [
      '월 2회 미스터리 쇼핑',
      '상세 리포트 및 개선 제안',
      '실버 신뢰 배지',
      '경쟁 업체 분석',
      '외부 플랫폼 리뷰 통합',
      '우선 고객 지원',
    ],
    highlights: ['가장 인기', '경쟁분석 포함'],
    gradientColors: HwahaeColors.gradientPrimary,
  ),
  const BusinessPricingPlan(
    id: 'pro',
    name: 'Pro',
    description: '프리미엄 매장 관리를 위한 최상위 플랜',
    monthlyPrice: 349000,
    yearlyPrice: 3490000,
    features: [
      '월 4회 미스터리 쇼핑',
      '프리미엄 리포트 + 컨설팅',
      '골드 신뢰 배지 (최상위 노출)',
      '전담 컨설턴트 배정',
      '경쟁 업체 심층 분석',
      '외부 플랫폼 리뷰 통합',
      'API 연동 및 데이터 내보내기',
    ],
    highlights: ['컨설팅 포함'],
    gradientColors: HwahaeColors.gradientAccent,
  ),
];

class BusinessFeatureComparison {
  final String feature;
  final String starter;
  final String growth;
  final String pro;

  const BusinessFeatureComparison({
    required this.feature,
    required this.starter,
    required this.growth,
    required this.pro,
  });
}

final businessFeatureComparisons = [
  const BusinessFeatureComparison(
    feature: '월 미스터리 쇼핑',
    starter: '1회',
    growth: '2회',
    pro: '4회',
  ),
  const BusinessFeatureComparison(
    feature: '리포트 유형',
    starter: '기본',
    growth: '상세',
    pro: '프리미엄',
  ),
  const BusinessFeatureComparison(
    feature: '신뢰 배지',
    starter: '브론즈',
    growth: '실버',
    pro: '골드',
  ),
  const BusinessFeatureComparison(
    feature: '경쟁 분석',
    starter: '-',
    growth: 'O',
    pro: '심층 분석',
  ),
  const BusinessFeatureComparison(
    feature: '컨설팅',
    starter: '-',
    growth: '-',
    pro: '전담 컨설턴트',
  ),
  const BusinessFeatureComparison(
    feature: '외부 리뷰 통합',
    starter: '-',
    growth: 'O',
    pro: 'O',
  ),
  const BusinessFeatureComparison(
    feature: 'API 연동',
    starter: '-',
    growth: '-',
    pro: 'O',
  ),
  const BusinessFeatureComparison(
    feature: '고객 지원',
    starter: 'FAQ',
    growth: '우선 지원',
    pro: '전담 매니저',
  ),
];

class BusinessPricingScreen extends ConsumerStatefulWidget {
  const BusinessPricingScreen({super.key});

  @override
  ConsumerState<BusinessPricingScreen> createState() =>
      _BusinessPricingScreenState();
}

class _BusinessPricingScreenState extends ConsumerState<BusinessPricingScreen>
    with SingleTickerProviderStateMixin {
  bool _isYearly = true;
  int _selectedPlanIndex = 1;
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
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: HwahaeColors.accent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: HwahaeColors.gradientAccent,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(
                        Icons.storefront_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '업체 요금제',
                        style: HwahaeTypography.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '신뢰 배지로 고객 전환율을 높이세요',
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildBillingToggle(),
            ),
          ),
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
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPricingCardsTab(),
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
          ...businessPricingPlans.asMap().entries.map((entry) {
            final index = entry.key;
            final plan = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPricingCard(plan, index),
            );
          }),
          const SizedBox(height: 24),
          _buildValueProposition(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPricingCard(BusinessPricingPlan plan, int index) {
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
            Row(
              children: [
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(price),
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
            ),
            if (_isYearly) ...[
              const SizedBox(height: 4),
              Text(
                '월 ${_formatCurrency(plan.yearlyPrice ~/ 12)}원 (${_formatCurrency(plan.getSavedAmount())}원 절약)',
                style: HwahaeTypography.captionMedium.copyWith(
                  color: HwahaeColors.success,
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: HwahaeColors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
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
                ...['Starter', 'Growth', 'Pro'].map((name) => Expanded(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: HwahaeTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: name == 'Growth'
                              ? HwahaeColors.primary
                              : HwahaeColors.textPrimary,
                        ),
                      ),
                    )),
              ],
            ),
          ),
          ...businessFeatureComparisons.asMap().entries.map((entry) {
            final index = entry.key;
            final comparison = entry.value;
            final isLast = index == businessFeatureComparisons.length - 1;

            return Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                    ? const BorderRadius.vertical(
                        bottom: Radius.circular(16))
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
                    child: _buildComparisonValue(comparison.starter),
                  ),
                  Expanded(
                    child: _buildComparisonValue(comparison.growth,
                        isHighlighted: true),
                  ),
                  Expanded(
                    child: _buildComparisonValue(comparison.pro),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          _buildValueProposition(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildComparisonValue(String value, {bool isHighlighted = false}) {
    if (value == 'O') {
      return Icon(
        Icons.check_circle,
        color: isHighlighted ? HwahaeColors.primary : HwahaeColors.success,
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
        color: isHighlighted ? HwahaeColors.primary : null,
        fontWeight: isHighlighted ? FontWeight.w600 : null,
      ),
    );
  }

  Widget _buildValueProposition() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                HwahaeColors.accent.withOpacity(0.1),
                HwahaeColors.accent.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
            border:
                Border.all(color: HwahaeColors.accent.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.trending_up, color: HwahaeColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    '신뢰 배지 효과',
                    style: HwahaeTypography.titleMedium.copyWith(
                      color: HwahaeColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatItem('고객 전환율', '+23% 향상'),
              const SizedBox(height: 8),
              _buildStatItem('재방문율', '+18% 증가'),
              const SizedBox(height: 8),
              _buildStatItem('리뷰 신뢰도', '평균 4.2배 높은 신뢰'),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
                    '14일 무료 체험',
                    style: HwahaeTypography.titleMedium.copyWith(
                      color: HwahaeColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '모든 플랜은 14일 무료 체험이 가능합니다.\n만족하지 않으면 언제든 취소하세요.',
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

  Widget _buildStatItem(String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: HwahaeColors.accent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: HwahaeTypography.badge.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: HwahaeTypography.bodySmall.copyWith(
              color: HwahaeColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCTA() {
    final selectedPlan = businessPricingPlans[_selectedPlanIndex];
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
              child: _isProcessingPayment
                  ? const Center(child: CircularProgressIndicator())
                  : HwahaePrimaryButton(
                      text: '구독 시작하기',
                      onPressed: () => _showPaymentSheet(selectedPlan),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentSheet(BusinessPricingPlan plan) {
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: HwahaeColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
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
              icon: Icons.account_balance,
              title: '계좌이체',
              subtitle: '실시간 이체',
              color: HwahaeColors.primary,
              onTap: () => _processPayment('transfer', plan),
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
      onTap: _isProcessingPayment ? null : onTap,
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
                  Text(title, style: HwahaeTypography.labelLarge),
                  Text(subtitle, style: HwahaeTypography.captionMedium),
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

  Future<void> _processPayment(String method, BusinessPricingPlan plan) async {
    if (_isProcessingPayment) return;
    setState(() => _isProcessingPayment = true);

    Navigator.pop(context);

    final paymentMethod = switch (method) {
      'card' => PaymentMethod.card,
      'kakaopay' => PaymentMethod.kakaoPay,
      'transfer' => PaymentMethod.virtualAccount,
      _ => PaymentMethod.card,
    };

    final price = plan.getPrice(_isYearly);
    final paymentService = PaymentService();

    String customerName = '업체 관리자';
    String customerEmail = 'business@amhangeoheung.com';
    try {
      final storage = const FlutterSecureStorage();
      final name = await storage.read(key: 'user_name');
      final email = await storage.read(key: 'user_email');
      if (name != null) customerName = name;
      if (email != null) customerEmail = email;
    } catch (_) {}

    final request = PaymentRequest(
      orderId: paymentService.generateOrderId(),
      orderName: '암행어흥 업체 ${plan.name} 플랜 (${_isYearly ? '연간' : '월간'})',
      amount: price,
      customerName: customerName,
      customerEmail: customerEmail,
      method: paymentMethod,
      isSubscription: true,
    );

    final result = await showPaymentScreen(
      context: context,
      request: request,
    );

    if (!mounted) return;

    if (result != null && result.success) {
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
      Navigator.pop(context);
    } else if (result != null) {
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
      case 'starter':
        return Icons.rocket_launch;
      case 'growth':
        return Icons.trending_up;
      case 'pro':
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
