import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../providers/profile_provider.dart';

class SpecialtiesScreen extends ConsumerStatefulWidget {
  const SpecialtiesScreen({super.key});

  @override
  ConsumerState<SpecialtiesScreen> createState() => _SpecialtiesScreenState();
}

class _SpecialtiesScreenState extends ConsumerState<SpecialtiesScreen> {
  final Set<String> _selectedCategories = {};
  bool _isLoading = false;

  final List<_CategoryItem> _categories = [
    _CategoryItem('음식점', Icons.restaurant, HwahaeColors.gradientWarm),
    _CategoryItem('카페', Icons.local_cafe, HwahaeColors.gradientAccent),
    _CategoryItem('뷰티', Icons.face, HwahaeColors.gradientPrimary),
    _CategoryItem('헬스/피트니스', Icons.fitness_center, HwahaeColors.gradientCool),
    _CategoryItem('병원/의료', Icons.local_hospital, [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
    _CategoryItem('교육', Icons.school, [Color(0xFF2196F3), Color(0xFF1565C0)]),
    _CategoryItem('숙박', Icons.hotel, [Color(0xFF9C27B0), Color(0xFF6A1B9A)]),
    _CategoryItem('레저/스포츠', Icons.sports_tennis, [Color(0xFFFF5722), Color(0xFFE64A19)]),
    _CategoryItem('반려동물', Icons.pets, [Color(0xFFFFB74D), Color(0xFFFF9800)]),
    _CategoryItem('자동차', Icons.directions_car, [Color(0xFF607D8B), Color(0xFF455A64)]),
    _CategoryItem('전자제품', Icons.devices, [Color(0xFF00BCD4), Color(0xFF0097A7)]),
    _CategoryItem('기타', Icons.category, [Color(0xFF9E9E9E), Color(0xFF616161)]),
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(profileProvider).user;
    if (user?.reviewerInfo?.specialties != null) {
      _selectedCategories.addAll(user!.reviewerInfo!.specialties!);
    }
  }

  Future<void> _saveSpecialties() async {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('최소 1개 이상의 카테고리를 선택해주세요'),
          backgroundColor: HwahaeColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(profileProvider.notifier).updateProfile(
      specialties: _selectedCategories.toList(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('전문 카테고리가 저장되었습니다'),
            backgroundColor: HwahaeColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('저장에 실패했습니다'),
            backgroundColor: HwahaeColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('전문 카테고리', style: HwahaeTypography.titleMedium),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSpecialties,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '저장',
                    style: HwahaeTypography.labelLarge.copyWith(
                      color: HwahaeColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 안내 메시지
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: HwahaeColors.primaryContainer,
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: HwahaeColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '전문 카테고리를 설정하면 관련 미션이 우선 배정됩니다',
                    style: HwahaeTypography.bodySmall.copyWith(
                      color: HwahaeColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 선택된 개수
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '선택된 카테고리',
                  style: HwahaeTypography.titleSmall,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: HwahaeColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedCategories.length}개',
                    style: HwahaeTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 카테고리 그리드
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategories.contains(category.name);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.remove(category.name);
                      } else {
                        _selectedCategories.add(category.name);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: category.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : HwahaeColors.surface,
                      borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : HwahaeColors.border,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: category.gradient[0].withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category.icon,
                          size: 32,
                          color: isSelected
                              ? Colors.white
                              : HwahaeColors.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.name,
                          style: HwahaeTypography.labelSmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : HwahaeColors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem {
  final String name;
  final IconData icon;
  final List<Color> gradient;

  _CategoryItem(this.name, this.icon, this.gradient);
}
