import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../data/repositories/season_repository.dart';
import '../../../../shared/widgets/ui/ui.dart';

class SeasonDetailScreen extends ConsumerStatefulWidget {
  final String seasonId;
  const SeasonDetailScreen({super.key, required this.seasonId});

  @override
  ConsumerState<SeasonDetailScreen> createState() => _SeasonDetailScreenState();
}

class _SeasonDetailScreenState extends ConsumerState<SeasonDetailScreen> {
  Map<String, dynamic>? _seasonData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSeason();
  }

  Future<void> _loadSeason() async {
    try {
      final data = await SeasonRepository().getSeasonDetail(widget.seasonId);
      if (mounted) setState(() { _seasonData = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text(_seasonData?['name'] ?? '시즌', style: HwahaeTypography.titleMedium),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: HwahaeColors.primary))
          : _seasonData == null
              ? const Center(child: Text('시즌을 찾을 수 없습니다'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final missions = _seasonData!['missions'] as List? ?? [];
    final endAt = DateTime.tryParse(_seasonData!['end_at'] ?? '');
    final remaining = endAt?.difference(DateTime.now());

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEA580C), Color(0xFFF97316)],
              ),
              borderRadius: BorderRadius.circular(HwahaeTheme.radiusXL),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _seasonData!['theme'] ?? '',
                  style: HwahaeTypography.labelMedium.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  _seasonData!['name'] ?? '',
                  style: HwahaeTypography.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_seasonData!['description'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _seasonData!['description'],
                    style: HwahaeTypography.bodyMedium.copyWith(color: Colors.white70),
                  ),
                ],
                if (remaining != null && remaining.inDays >= 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      remaining.inDays > 0 ? 'D-${remaining.inDays}' : '오늘 마감!',
                      style: HwahaeTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '시즌 미션 (${missions.length}개)',
              style: HwahaeTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final mission = missions[index];
              return ListTile(
                title: Text(mission['category'] ?? '미션'),
                subtitle: Text(mission['region'] ?? ''),
                trailing: Text(
                  '${mission['reviewer_fee'] ?? 0}원',
                  style: HwahaeTypography.labelMedium.copyWith(
                    color: HwahaeColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => context.push('/missions/${mission['id']}'),
              );
            },
            childCount: missions.length,
          ),
        ),
        const SliverBottomSpacer.plain(),
      ],
    );
  }
}
