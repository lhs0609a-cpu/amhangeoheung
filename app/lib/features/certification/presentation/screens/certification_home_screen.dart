import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/hwahae_colors.dart';
import '../../providers/certification_provider.dart';
import '../widgets/certification_badge.dart';

class CertificationHomeScreen extends ConsumerWidget {
  const CertificationHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(certificationNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('리뷰어 인증 프로그램'),
      ),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: HwahaeColors.primary)),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (status) => _buildContent(context, status),
      ),
    );
  }

  Widget _buildContent(BuildContext context, status) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 수료증 표시
          if (status.isCertified) _buildCertificate(context, status),
          if (status.isCertified) const SizedBox(height: 24),

          // 인증 상태 카드
          _buildStatusCard(context, status),
          const SizedBox(height: 24),

          // 인증 배지
          if (status.isCertified)
            Center(child: CertificationBadge(level: status.certificationLevel)),
          if (status.isCertified) const SizedBox(height: 24),

          // 3일 과정 로드맵
          const Text(
            '교육 과정',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildDayCard(context, status, 1, '암행어흥의 철학', '왜 객관적 리뷰가 중요한가, 평가 기준 학습'),
          const SizedBox(height: 12),
          _buildDayCard(context, status, 2, '현장 행동 수칙', '신분 노출 방지, 사진 촬영 가이드, 문제 대응'),
          const SizedBox(height: 12),
          _buildDayCard(context, status, 3, '리뷰 작성 실습', '객관적 글쓰기, 실전 연습, 종합 시험'),

          const SizedBox(height: 24),

          // 품질 점수
          if (status.qualityScore > 0)
            _buildQualityCard(status),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, status) {
    final progress = _calculateOverallProgress(status);
    Color progressColor = Colors.blue;
    String statusText = '교육 진행 중';
    IconData statusIcon = Icons.school;

    if (status.isCertified) {
      progressColor = Colors.green;
      statusText = '인증 완료';
      statusIcon = Icons.verified;
    } else if (status.status == 'suspended') {
      progressColor = Colors.red;
      statusText = '인증 정지';
      statusIcon = Icons.warning;
    } else if (status.status == 'failed') {
      progressColor = Colors.orange;
      statusText = '시험 불합격';
      statusIcon = Icons.refresh;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(statusIcon, color: progressColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(statusText,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: progressColor)),
                      if (!status.isCertified)
                        Text('전체 진행률 ${(progress * 100).round()}%',
                            style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, status, int day, String title, String subtitle) {
    final isCompleted = status.isDayCompleted(day);
    final isUnlocked = status.isDayUnlocked(day);
    final dayProg = status.dayProgress[day];

    IconData icon;
    Color color;
    if (isCompleted) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (isUnlocked) {
      icon = Icons.play_circle_fill;
      color = Colors.blue;
    } else {
      icon = Icons.lock;
      color = Colors.grey;
    }

    return Card(
      elevation: isUnlocked ? 2 : 0,
      color: isUnlocked ? null : Colors.grey[100],
      child: ListTile(
        leading: Icon(icon, color: color, size: 36),
        title: Text(
          'Day $day: $title',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isUnlocked ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle,
                style: TextStyle(color: isUnlocked ? null : Colors.grey)),
            if (dayProg != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${dayProg.completed}/${dayProg.total} 모듈 완료',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
        trailing: isUnlocked && !isCompleted
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : null,
        onTap: isUnlocked
            ? () => context.push('/certification/training/$day')
            : null,
      ),
    );
  }

  Widget _buildQualityCard(status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('리뷰 품질 점수',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${status.qualityScore.toStringAsFixed(1)}점',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: status.qualityScore >= 70 ? Colors.green : Colors.orange,
                  ),
                ),
                const Spacer(),
                if (status.warningCount > 0)
                  Chip(
                    label: Text('경고 ${status.warningCount}회'),
                    backgroundColor: Colors.orange[100],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificate(BuildContext context, status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF9F3E3), Color(0xFFFFF8E1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium, size: 48, color: Color(0xFFD4AF37)),
          const SizedBox(height: 12),
          const Text(
            '암행어사 수료증',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF5D4037),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFD4AF37), thickness: 1),
          const SizedBox(height: 12),
          Text(
            '위 사람은 암행어흥 리뷰어 교육 과정을\n성실히 이수하였음을 인증합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.brown[700],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          if (status.certificationDate != null)
            Text(
              '인증일: ${_formatDate(status.certificationDate)}',
              style: TextStyle(fontSize: 13, color: Colors.brown[600]),
            ),
          const SizedBox(height: 4),
          Text(
            '인증번호: ${status.certificationId ?? 'N/A'}',
            style: TextStyle(fontSize: 12, color: Colors.brown[400]),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  double _calculateOverallProgress(status) {
    int completed = 0;
    int total = 0;
    for (int day = 1; day <= 3; day++) {
      final dp = status.dayProgress[day];
      if (dp != null) {
        completed += dp.completed;
        total += dp.total;
      }
    }
    if (status.isCertified) return 1.0;
    if (total == 0) return 0.0;
    return completed / total;
  }
}
