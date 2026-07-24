import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/hwahae_colors.dart';
import '../../../../core/theme/hwahae_typography.dart';
import '../../../../core/theme/hwahae_theme.dart';
import '../../data/repositories/review_request_repository.dart';

class RequestReviewScreen extends ConsumerStatefulWidget {
  final String businessId;
  const RequestReviewScreen({super.key, required this.businessId});

  @override
  ConsumerState<RequestReviewScreen> createState() => _RequestReviewScreenState();
}

class _RequestReviewScreenState extends ConsumerState<RequestReviewScreen> {
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      await ReviewRequestRepository().createRequest(
        widget.businessId,
        message: _messageController.text.isNotEmpty ? _messageController.text : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리뷰 요청이 등록되었습니다!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('요청 실패: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HwahaeColors.background,
      appBar: AppBar(
        backgroundColor: HwahaeColors.surface,
        title: Text('리뷰 요청', style: HwahaeTypography.titleMedium),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HwahaeColors.primaryContainer,
                borderRadius: BorderRadius.circular(HwahaeTheme.radiusLG),
              ),
              child: Column(
                children: [
                  const Icon(Icons.rate_review_rounded, size: 48, color: HwahaeColors.primary),
                  const SizedBox(height: 12),
                  Text(
                    '이 업체의 리뷰를 요청하세요',
                    style: HwahaeTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '요청이 많아지면 업체에 알려드려요.\n미션이 등록되면 전문 리뷰어가 방문합니다.',
                    style: HwahaeTypography.bodySmall.copyWith(color: HwahaeColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('메시지 (선택)', style: HwahaeTypography.labelMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: '궁금한 점이나 확인하고 싶은 내용을 적어주세요',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HwahaeColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HwahaeTheme.radiusMD)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('리뷰 요청하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
