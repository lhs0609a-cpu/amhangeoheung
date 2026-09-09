import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/business_categories.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../shared/widgets/ui/ui.dart';

typedef BusinessSearch = Future<List<Map<String, dynamic>>> Function(
    String query, String? category);

Future<List<Map<String, dynamic>>> searchBusinesses(
    String query, String? category) async {
  final response =
      await ApiClient.instance.dio.get('/businesses/search', queryParameters: {
    if (query.isNotEmpty) 'q': query,
    if (category != null) 'category': category,
  });
  final data = response.data;
  if (data is! Map ||
      data['success'] != true ||
      data['data'] is! Map ||
      data['data']['businesses'] is! List) {
    throw const FormatException('Invalid search response');
  }
  return (data['data']['businesses'] as List)
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .where((entry) =>
          entry['id'] is String && (entry['id'] as String).isNotEmpty)
      .toList();
}

class SearchScreen extends StatefulWidget {
  const SearchScreen(
      {super.key,
      this.initialCategory,
      this.initialQuery = '',
      this.search = searchBusinesses});
  final String? initialCategory;
  final String initialQuery;
  final BusinessSearch search;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  late String _category;
  Timer? _debounce;
  int _generation = 0;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _searched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _category = businessCategories.contains(widget.initialCategory)
        ? widget.initialCategory!
        : '전체';
    if (_canSearch) _schedule(immediate: true);
  }

  bool get _canSearch =>
      _controller.text.trim().length >= 2 ||
      (_controller.text.trim().isEmpty && _category != '전체');

  @override
  void dispose() {
    ++_generation;
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _schedule({bool immediate = false}) {
    _debounce?.cancel();
    // 입력 즉시 무효화해야 디바운스 대기 중 돌아온 이전 응답도 폐기된다.
    final generation = ++_generation;
    setState(() {
      _results = [];
      _error = null;
      _searched = false;
      _isLoading = _canSearch;
    });
    if (!_canSearch) return;
    final query = _controller.text.trim();
    final category = _category == '전체' ? null : _category;
    if (immediate) {
      _performSearch(query, category, generation);
    } else {
      _debounce = Timer(const Duration(milliseconds: 350),
          () => _performSearch(query, category, generation));
    }
  }

  Future<void> _performSearch(
      String query, String? category, int generation) async {
    try {
      final results = await widget.search(query, category);
      if (!mounted || generation != _generation) return;
      setState(() {
        _results = results;
        _isLoading = false;
        _searched = true;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _isLoading = false;
        _searched = true;
        _error = '검색 결과를 불러오지 못했어요.';
      });
    }
  }

  void _clear() {
    _controller.clear();
    _schedule(immediate: true);
  }

  void _reset() {
    _controller.clear();
    _category = '전체';
    _schedule();
  }

  @override
  Widget build(BuildContext context) => AppScreen(
        title: '가게 찾기',
        hasBottomNav: true,
        scrollable: false,
        child: AppLayout.constrain(CustomScrollView(slivers: [
          SliverPadding(
            padding:
                EdgeInsets.symmetric(horizontal: AppLayout.gutterOf(context)),
            sliver: SliverList.list(children: [
              const SizedBox(height: 8),
              AppTextField(
                controller: _controller,
                onChanged: (_) => _schedule(),
                onSubmitted: (_) => _schedule(immediate: true),
                textInputAction: TextInputAction.search,
                hint: '가게 이름 또는 설명으로 검색',
                prefixIcon: Icons.search_rounded,
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '검색어 지우기',
                        onPressed: _clear,
                        icon: const Icon(Icons.cancel_outlined)),
              ),
              const SizedBox(height: 12),
              Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: businessCategories
                      .map((category) => ChoiceChip(
                            label: Text(category),
                            selected: _category == category,
                            showCheckmark: false,
                            selectedColor: HwahaeColors.primary,
                            labelStyle: HwahaeTypography.bodySmall
                                .copyWith(color: HwahaeColors.textPrimary),
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            onSelected: (_) {
                              _category = category;
                              _schedule(immediate: true);
                            },
                          ))
                      .toList()),
              const SizedBox(height: 20),
              if (_isLoading) ...[
                const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: 16),
                Semantics(
                    liveRegion: true,
                    child: Text('조건에 맞는 가게를 찾고 있어요',
                        style: HwahaeTypography.bodyMedium)),
              ] else if (_error != null)
                AppErrorState.fromMessage(_error!,
                    onRetry: () => _schedule(immediate: true))
              else if (!_searched)
                AppEmptyState(
                    icon: Icons.search_rounded,
                    title: '궁금한 가게부터 찾아보세요',
                    message: '이름을 두 글자 이상 입력하거나 업종을 골라보세요.',
                    showMascot: true,
                    actionLabel: '카페 둘러보기',
                    onAction: () {
                      _category = '카페';
                      _schedule(immediate: true);
                    })
              else if (_results.isEmpty)
                AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: '조건에 맞는 가게가 없어요',
                    message: '검색어를 바꾸거나 업종 조건을 풀어보세요.',
                    actionLabel: '검색 조건 초기화',
                    onAction: _reset)
              else ...[
                Semantics(
                    liveRegion: true,
                    child: Text(
                        '${_category == '전체' ? '검색' : _category} 결과 ${_results.length}개${_results.length >= 50 ? ' · 최대 50개 표시' : ''}',
                        style: HwahaeTypography.titleSmall)),
                const SizedBox(height: 6),
                Text('방문 자료와 평가 내용은 감찰 기록에서 확인하세요.',
                    style: HwahaeTypography.bodySmall),
                const SizedBox(height: 16),
              ],
            ]),
          ),
          if (!_isLoading && _error == null)
            SliverPadding(
              padding:
                  EdgeInsets.symmetric(horizontal: AppLayout.gutterOf(context)),
              sliver: SliverList.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final business = _results[index];
                    return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BusinessSearchCard(
                            business: business,
                            onTap: () => context.push(
                                '/trust/${Uri.encodeComponent(business['id'] as String)}')));
                  }),
            ),
          const SliverBottomSpacer(),
        ])),
      );
}

class BusinessSearchCard extends StatelessWidget {
  const BusinessSearchCard(
      {super.key, required this.business, required this.onTap});
  final Map<String, dynamic> business;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rating = business['average_rating'] ?? business['avg_rating'];
    final count = business['total_reviews'];
    final location = [business['category'], business['address_city']]
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .join(' · ');
    return AppCard(
        style: AppCardStyle.outlined,
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: HwahaeColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.storefront_outlined,
                    color: HwahaeColors.textSecondary)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(business['name'] as String? ?? '업체명 미제공',
                      style: HwahaeTypography.titleMedium),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(location, style: HwahaeTypography.bodySmall)
                  ],
                ])),
          ]),
          const SizedBox(height: 14),
          Wrap(spacing: 12, runSpacing: 6, children: [
            if (count is num)
              Text('리뷰 ${count.toInt()}개', style: HwahaeTypography.bodySmall),
            if (rating is num &&
                rating.isFinite &&
                rating > 0 &&
                count is num &&
                count > 0)
              Text('평균 ${rating.toStringAsFixed(1)}점',
                  style: HwahaeTypography.bodySmall),
            if (count == null)
              Text('리뷰 수 미제공', style: HwahaeTypography.bodySmall),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: Text('감찰 기록 보기', style: HwahaeTypography.bodyMedium)),
            const Icon(Icons.arrow_forward_rounded, size: 18)
          ]),
        ]));
  }
}
