import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().length >= 2) {
        _performSearch(query.trim());
      } else {
        setState(() {
          _results = [];
          _error = null;
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

      if (data['success'] == true) {
        setState(() {
          _results = data['data']['businesses'] as List? ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[SearchScreen] Error searching: $e');
      setState(() {
        _isLoading = false;
        _error = '검색 중 오류가 발생했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: '업체, 미션, 리뷰 검색',
            hintStyle: HwahaeTypography.bodyMedium.copyWith(
              color: HwahaeColors.textTertiary,
            ),
            border: InputBorder.none,
            filled: false,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _results = [];
                        _error = null;
                      });
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: HwahaeColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: HwahaeColors.error),
            const SizedBox(height: 16),
            Text(_error!, style: HwahaeTypography.bodyMedium),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                if (_controller.text.trim().length >= 2) {
                  _performSearch(_controller.text.trim());
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_controller.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: HwahaeColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              '검색어를 입력해주세요',
              style: HwahaeTypography.bodyMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: HwahaeColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: HwahaeTypography.bodyMedium.copyWith(
                color: HwahaeColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final business = _results[index] as Map<String, dynamic>;
        return _SearchResultCard(
          business: business,
          onTap: () => context.push('/trust/${business['id']}'),
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> business;
  final VoidCallback onTap;

  const _SearchResultCard({required this.business, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HwahaeColors.surface,
          borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD),
          border: Border.all(color: HwahaeColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: HwahaeColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.storefront,
                color: HwahaeColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business['name'] ?? '',
                    style: HwahaeTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${business['category'] ?? ''} • ${business['address_city'] ?? ''}',
                    style: HwahaeTypography.captionMedium.copyWith(
                      color: HwahaeColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (business['avg_rating'] != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: HwahaeColors.warning),
                  const SizedBox(width: 2),
                  Text(
                    '${(business['avg_rating'] as num).toStringAsFixed(1)}',
                    style: HwahaeTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
