import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/brand_assets.dart';

/// The brand's mission is the entry point, not a generic recommendation banner.
class DiscoveryBanner extends StatelessWidget {
  const DiscoveryBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: const Color(0xFF182523),
            borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            Image.asset(BrandAssets.dispatch,
                width: double.infinity, height: 210, fit: BoxFit.cover),
            Positioned(
                left: 20,
                top: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  color: const Color(0xFFBC4938),
                  child: const Text('암행어사 출두요',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                )),
          ]),
          Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('도무지 못 믿을 리뷰,',
                        style:
                            TextStyle(color: Color(0xFFD0C7B7), fontSize: 15)),
                    const SizedBox(height: 8),
                    const Text('이제, 어사가\n직접 확인합니다.',
                        style: TextStyle(
                            color: Color(0xFFF8F3E8),
                            fontSize: 30,
                            height: 1.25,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 14),
                    const Text('좋은 말보다 진짜 경험.\n이 세상의 모든 작업 리뷰가 사라질 때까지.',
                        style: TextStyle(
                            color: Color(0xFFD0C7B7),
                            fontSize: 13,
                            height: 1.7)),
                    const SizedBox(height: 20),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFEF9B35),
                              foregroundColor: const Color(0xFF182523)),
                          onPressed: () => context.push('/reviews'),
                          child: const Text('어사들의 현장 기록')),
                      TextButton(
                          style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFF8F3E8)),
                          onPressed: () => context.push('/inspector-code'),
                          child: const Text('우리의 원칙 →')),
                    ]),
                  ])),
        ]),
      ),
    );
  }
}
