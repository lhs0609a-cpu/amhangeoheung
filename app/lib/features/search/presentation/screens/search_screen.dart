import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';

/// 업체 검색. 소비자 유형의 탭 화면이다.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<dynamic> _results = [];
  bool _isLoading = false;
  String? _error;

  /// 검색을 한 번이라도 돌린 뒤인지. "결과 없음"과 "아직 안 쳤음"을 구분한다.
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // 지우기 버튼은 입력 즉시 나타나야 한다. 디바운스 뒤에 setState 하면
    // 글자를 지울 때까지 버튼이 안 보였다.
    setState(() {});

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().length >= 2) {
        _performSearch(query.trim());
      } else {
        setState(() {
          _results = [];
          _error = null;
          _searched = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient.instance.dio.get(
        '/businesses/search',
        queryParameters: {'q': query},
      );
      final data = response.data;

      if (!mounted) return;
      setState(() {
        _results = data['success'] == true
            ? (data['data']['businesses'] as List? ?? [])
            : [];
        _isLoading = false;
        _searched = true;
      });
    } catch (e) {
      debugPrint('[SearchScreen] Error searching: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _searched = true;
        _error = '검색 중 오류가 발생했습니다.';
      });
    }
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _results = [];
      _error = null;
      _searched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gutter = AppLayout.gutterOf(context);

    return AppScreen(
      title: '검색',
      hasBottomNav: true,
      // 검색창은 스크롤과 함께 사라지면 안 된다. 결과를 보다가 검색어를
      // 고치려면 매번 맨 위로 올라가야 한다.
      scrollable: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 12),
            child: _SearchField(
              controller: _controller,
              onChanged: _onSearchChanged,
              onClear: _controller.text.isEmpty ? null : _clear,
            ),
          ),
          Expanded(child: _buildBody(gutter)),
        ],
      ),
    );
  }

  Widget _buildBody(double gutter) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: HwahaeColors.primary),
      );
    }

    if (_error != null) {
      return SingleChildScrollView(
        child: AppErrorState.fromMessage(
          _error!,
          onRetry: () {
            final q = _controller.text.trim();
            if (q.length >= 2) _performSearch(q);
          },
        ),
      );
    }

    if (!_searched) {
      return const SingleChildScrollView(
        child: AppEmptyState(
          icon: Icons.search_rounded,
          title: '어느 가게가 궁금해?',
          message: '두 글자 이상 입력하면 찾아볼게',
          showMascot: true,
        ),
      );
    }

    if (_results.isEmpty) {
      return const SingleChildScrollView(
        child: AppEmptyState(
          icon: Icons.search_off_rounded,
          title: '찾는 가게가 없네',
          message: '이름을 조금 바꿔서 다시 찾아봐',
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        gutter,
        0,
        gutter,
        AppLayout.bottomScrollInset(context),
      ),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppLayout.cardGap),
      itemBuilder: (context, index) {
        final business = (_results[index] as Map).cast<String, dynamic>();
        return _SearchResultCard(
          business: business,
          onTap: () => context.push('/trust/${business['id']}'),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      hint: '업체 이름으로 찾기',
      prefixIcon: Icons.search_rounded,
      suffixIcon: onClear == null
          ? null
          : IconButton(
              icon: const Icon(Icons.cancel_rounded, size: 18),
              color: HwahaeColors.textTertiary,
              tooltip: '지우기',
              onPressed: onClear,
            ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> business;
  final VoidCallback onTap;

  const _SearchResultCard({required this.business, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rating = (business['avg_rating'] as num?)?.toDouble();
    final category = business['category'] ?? '';
    final city = business['address_city'] ?? '';
    final where = [category, city].where((s) => '$s'.isNotEmpty).join(' · ');

    return AppCard(
      style: AppCardStyle.outlined,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: HwahaeColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: HwahaeColors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business['name'] ?? '',
                  style: HwahaeTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (where.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    where,
                    style: HwahaeTypography.captionMedium.copyWith(
                      color: HwahaeColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (rating != null) ...[
            const SizedBox(width: 8),
            AppBadge.rating(rating),
          ],
        ],
      ),
    );
  }
}
