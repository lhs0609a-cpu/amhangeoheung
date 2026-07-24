import 'package:flutter_test/flutter_test.dart';
import 'package:amhangeoheung_app/features/mission/data/models/mission_model.dart';

void main() {
  group('MissionModel.fromJson', () {
    test('snake_case 백엔드 응답을 파싱한다', () {
      final m = MissionModel.fromJson({
        'id': 'm1',
        'business_id': 'b1',
        'mission_type': 'visit',
        'status': 'recruiting',
        'reviewer_fee': 15000,
        'reward_type': 'cash',
        'max_applicants': 10,
        'gps_required': true,
      });

      expect(m.id, 'm1');
      expect(m.businessId, 'b1');
      expect(m.missionType, 'visit');
      expect(m.reviewerFee, 15000);
      expect(m.rewardType, 'cash');
      expect(m.maxApplicants, 10);
      expect(m.gpsRequired, true);
    });

    test('camelCase 응답도 파싱한다', () {
      final m = MissionModel.fromJson({
        'id': 'm2',
        'businessId': 'b2',
        'missionType': 'delivery',
        'reviewerFee': 20000,
      });

      expect(m.businessId, 'b2');
      expect(m.missionType, 'delivery');
      expect(m.reviewerFee, 20000);
    });

    test('누락 필드는 안전한 기본값을 사용한다', () {
      final m = MissionModel.fromJson({'id': 'm3'});
      expect(m.status, 'recruiting');
      expect(m.reviewerFee, 0);
      expect(m.rewardType, 'cash');
      expect(m.maxApplicants, 20);
      expect(m.gpsRequired, false);
    });

    test('무료체험(free_experience) 보상 타입을 파싱한다', () {
      final m = MissionModel.fromJson({
        'id': 'm4',
        'reward_type': 'free_experience',
        'experience_description': '디저트 세트 무료 제공',
        'experience_value': 25000,
      });
      expect(m.rewardType, 'free_experience');
      expect(m.experienceDescription, '디저트 세트 무료 제공');
      expect(m.experienceValue, 25000);
    });
  });

  group('MissionModel 계산 getter', () {
    test('상태 플래그와 표시명', () {
      final m = MissionModel.fromJson({'id': 'm', 'status': 'recruiting'});
      expect(m.isRecruiting, true);
      expect(m.isAssigned, false);
      expect(m.statusDisplayName, '모집중');
    });

    test('visibility 로 히든/시즌 미션을 판별한다', () {
      final hidden = MissionModel.fromJson({'id': 'm', 'visibility': 'hidden'});
      final season = MissionModel.fromJson({'id': 'm', 'visibility': 'season'});
      expect(hidden.isHidden, true);
      expect(season.isSeason, true);
    });

    test('visitDeadline 은 배정 시각 + 3일', () {
      final assignedAt = DateTime(2026, 1, 1, 12);
      final m = MissionModel.fromJson({
        'id': 'm',
        'assigned_at': assignedAt.toIso8601String(),
      });
      expect(m.visitDeadline, assignedAt.add(const Duration(days: 3)));
    });

    test('배정되지 않은 미션의 visitDeadline 은 null', () {
      final m = MissionModel.fromJson({'id': 'm'});
      expect(m.visitDeadline, isNull);
      expect(m.daysUntilVisitDeadline, isNull);
    });
  });
}
