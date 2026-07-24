import 'package:flutter_test/flutter_test.dart';
import 'package:amhangeoheung_app/core/config/company_info.dart';

void main() {
  group('CompanyInfo', () {
    test('dart-define 미주입 시 필수 법적 정보는 placeholder 상태', () {
      // 테스트 빌드에는 COMPANY_* dart-define 이 없으므로 미완성으로 판정되어야 한다.
      expect(CompanyInfo.hasUnfilledLegalInfo, true);
    });

    test('비운영(development) 환경에서 assertReleaseReady 는 예외를 던지지 않는다', () {
      // EnvironmentConfig 기본값은 development → 운영이 아니므로 통과해야 한다.
      expect(CompanyInfo.assertReleaseReady, returnsNormally);
    });

    test('warnIfUnfilled 는 예외 없이 동작한다', () {
      expect(CompanyInfo.warnIfUnfilled, returnsNormally);
    });

    test('기본 이메일/패키지 상수는 채워져 있다', () {
      expect(CompanyInfo.privacyEmail, isNotEmpty);
      expect(CompanyInfo.androidPackageId, contains('amhangeoheung'));
    });
  });
}
