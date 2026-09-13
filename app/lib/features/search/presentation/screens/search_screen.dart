import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../shared/widgets/content_image.dart';

class SearchScreen extends StatefulWidget {
  final String? initialCategory;
  const SearchScreen({super.key, this.initialCategory});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;
  String? _category;
  String? _error;
  bool _loading = false;
  bool _searched = false;
  List<dynamic> _results = [];
  static const _categories = ['음식점', '카페', '뷰티', '건강', '레저', '교육'];

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    if (_category != null) _search();
  }

  @override
  void didUpdateWidget(covariant SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != oldWidget.initialCategory) {
      _category = widget.initialCategory;
      _changed(_controller.text);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    _debounce?.cancel();
    _requestId++;
    setState(() {
      _results = [];
      _error = null;
      _loading = false;
      _searched = false;
    });
    if (value.trim().isEmpty && _category == null) return;
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    _debounce?.cancel();
    final query = _controller.text.trim();
    if (query.isEmpty && _category == null) return;
    final request = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.instance.dio.get(
        '/businesses/search',
        queryParameters: {
          if (query.isNotEmpty) 'q': query,
          if (_category != null) 'category': _category,
        },
      );
      if (!mounted || request != _requestId) return;
      if (response.data['success'] != true) throw StateError('Search failed');
      setState(() {
        _results = response.data['data']['businesses'] as List? ?? [];
        _loading = false;
        _searched = true;
      });
    } catch (_) {
      if (!mounted || request != _requestId) return;
      setState(() {
        _loading = false;
        _error = '검색 결과를 불러오지 못했어요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('발견하기')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _controller,
              maxLength: 100,
              textInputAction: TextInputAction.search,
              onChanged: _changed,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: '어떤 업체를 찾고 있나요?',
                counterText: '',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '검색어 지우기',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          _changed('');
                        },
                      ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final category in ['전체', ..._categories])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: category == (_category ?? '전체'),
                      onSelected: (_) {
                        setState(
                          () => _category = category == '전체' ? null : category,
                        );
                        _changed(_controller.text);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return _message(
        Icons.wifi_off_rounded,
        _error!,
        action: TextButton.icon(
          onPressed: _search,
          icon: const Icon(Icons.refresh),
          label: const Text('다시 시도'),
        ),
      );
    if (!_searched)
      return _message(
        Icons.travel_explore_rounded,
        '우리 동네의 새로운 발견',
        subtitle: '업체 이름을 검색하거나 카테고리를 선택해보세요.',
      );
    if (_results.isEmpty)
      return _message(
        Icons.search_off_rounded,
        '아직 일치하는 업체가 없어요',
        subtitle: '다른 검색어나 카테고리로 찾아보세요.',
      );
    return RefreshIndicator(
      onRefresh: _search,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _results.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0)
            return Text(
              '검색 결과 ${_results.length}곳',
              style: Theme.of(context).textTheme.titleSmall,
            );
          final business = _results[index - 1] as Map<String, dynamic>;
          final photo = ContentImage.firstUrl(business['images']);
          final rating = business['average_rating'];
          return Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: business['id'] == null
                  ? null
                  : () => context.push('/trust/${business['id']}'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    ContentImage(
                      url: photo,
                      label: '${business['name']} 업체 사진',
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business['name'] ?? '업체',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            [business['category'], business['address_city']]
                                .whereType<String>()
                                .where((s) => s.isNotEmpty)
                                .join(' · '),
                            style: const TextStyle(
                              color: HwahaeColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: HwahaeColors.ratingStar,
                                size: 17,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating is num
                                    ? rating.toStringAsFixed(1)
                                    : '평점 없음',
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '리뷰 ${business['total_reviews'] ?? 0}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: HwahaeColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: HwahaeColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _message(
    IconData icon,
    String title, {
    String? subtitle,
    Widget? action,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: HwahaeColors.primaryContainer,
              child: Icon(icon, size: 32, color: HwahaeColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: HwahaeColors.textSecondary),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 12), action],
          ],
        ),
      ),
    );
  }
}
