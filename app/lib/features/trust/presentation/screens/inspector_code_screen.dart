import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/brand_assets.dart';
import '../../../../core/theme/hwahae_colors.dart';

class InspectorCodeScreen extends StatelessWidget {
  const InspectorCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('암행어흥의 약속')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('이 세상의 모든\n작업 리뷰가 사라질 때까지.',
            style: TextStyle(
                fontSize: 30, height: 1.35, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        const Text(
            '우리는 좋은 평가를 약속하지 않습니다. 직접 확인한 경험과 근거가 있는, 솔직하고 대담한 리뷰를 지향합니다.',
            style: TextStyle(fontSize: 15, height: 1.8)),
        const SizedBox(height: 24),
        _chapter(
            '01  아무나 어사가 될 수 없다',
            '선발 시험을 통과한 어사',
            '교육과 리뷰 작성 실습, 종합 시험을 거쳐 자격을 얻습니다. 합격은 시작이고, 활동 이후에도 리뷰 품질을 점검합니다.',
            BrandAssets.exam),
        _chapter(
            '02  직접 가서, 직접 확인한다',
            '암행어사 출두요',
            '업장에 파견된 어사가 방문 경험을 기록합니다. 좋았던 점도, 아쉬웠던 점도 구체적으로 남깁니다. 대담한 평가는 사실과 근거 위에 있어야 합니다.',
            BrandAssets.dispatch),
        _chapter(
            '03  마패는 돈으로 살 수 없다',
            '청탁에는 파면 원칙',
            '업체의 돈이나 혜택을 받고 평가를 바꾸는 행위는 어사의 자격과 양립할 수 없습니다. 신고와 조사, 소명을 거쳐 위반이 확인되면 자격 박탈과 해당 리뷰의 신뢰 표시 회수를 적용하는 원칙입니다.',
            BrandAssets.integrity),
        const SizedBox(height: 8),
        const Text('어사의 등급과 리뷰의 근거는 다릅니다',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        const Text(
            '어사 등급은 축적한 활동과 품질을, 리뷰의 증거 표시는 해당 방문의 확인 수준을 나타냅니다. 높은 등급만으로 모든 리뷰가 사실이라고 단정하지 않습니다.',
            style: TextStyle(height: 1.8)),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final grade in ['초임 어사', '정식 어사', '상급 어사', '수석 어사'])
            Chip(
                avatar: Image.asset(BrandAssets.mapae, width: 24),
                label: Text(grade)),
        ]),
        const SizedBox(height: 24),
        FilledButton(
            onPressed: () => context.push('/certification'),
            child: const Text('어사 선발 과정 보기')),
        const SizedBox(height: 10),
        OutlinedButton(
            onPressed: () => context.push('/support'),
            child: const Text('청탁·작업 리뷰 제보하기')),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _chapter(String eyebrow, String title, String body, String asset) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(asset,
                  width: double.infinity, height: 220, fit: BoxFit.cover)),
          const SizedBox(height: 18),
          Text(eyebrow,
              style: const TextStyle(
                  color: HwahaeColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(title,
              style:
                  const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.8)),
        ]),
      );
}
