import 'package:flutter_test/flutter_test.dart';
import 'package:amhangeoheung_app/features/auth/data/models/user_model.dart';

void main() {
  test('database profile fields preserve role, grade and account after reload',
      () {
    final user = UserModel.fromJson({
      'id': 'user',
      'user_type': 'reviewer',
      'profile_image': 'avatar.jpg',
      'reviewer_grade': 'senior',
      'completed_missions': 12,
      'trust_score': 4.5,
      'specialties': ['카페'],
      'bank_name': '테스트은행',
      'bank_account_number': '1234',
      'bank_account_holder': '테스터',
      'premium_active': true,
      'premium_expires_at': '2026-12-31T00:00:00Z',
    });
    expect(user.isReviewer, isTrue);
    expect(user.profileImage, 'avatar.jpg');
    expect(user.reviewerInfo?.grade, 'senior');
    expect(user.reviewerInfo?.completedMissions, 12);
    expect(user.reviewerInfo?.trustScore, 4.5);
    expect(user.bankAccount, '1234');
    expect(user.premiumInfo?.isActive, isTrue);
    final restored = UserModel.fromJson(user.toJson());
    expect(restored.bankHolder, '테스터');
    expect(restored.reviewerInfo?.specialties, ['카페']);
  });

  test('camel case login response retains nested reviewer information', () {
    final user = UserModel.fromJson({
      'userType': 'reviewer',
      'isVerified': true,
      'reviewer': {'grade': 'regular', 'completedMissions': 3, 'trustScore': 4},
    });
    expect(user.isVerified, isTrue);
    expect(user.reviewer?.grade, 'regular');
    expect(user.reviewer?.trustScore, 4);
    expect(user.bankAccount, isNull);
  });
}
