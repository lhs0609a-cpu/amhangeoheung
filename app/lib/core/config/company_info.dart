import 'package:flutter/foundation.dart';
import 'environment.dart';

/// 회사 법적 정보 (사업자 정보, 연락처 등)
///
/// 값은 빌드 시 `--dart-define` 로 주입한다. 미주입 시 기본값은 placeholder 이며,
/// 운영(production) 빌드에서 placeholder 가 남아있으면 [assertReleaseReady] 가
/// 예외를 던져 실수로 출시되는 것을 막는다.
/// 전자상거래법/위치정보법상 사업자등록번호·대표자명·주소·고객센터 표기는 필수.
/// 모든 화면/약관이 이 상수를 참조하므로, 주입값만 바꾸면 전체에 반영된다.
///
/// 예)
/// flutter build appbundle \
///   --dart-define=APP_ENV=production \
///   --dart-define=COMPANY_CEO_NAME=홍길동 \
///   --dart-define=COMPANY_BRN=123-45-67890 \
///   --dart-define=COMPANY_MAIL_ORDER_NO=2026-서울강남-01234 \
///   --dart-define=COMPANY_ADDRESS="서울특별시 강남구 ..." \
///   --dart-define=COMPANY_CS_PHONE=1600-0000 \
///   --dart-define=IOS_APP_ID=id1234567890
class CompanyInfo {
  CompanyInfo._();

  static const String _placeholder = '[출시 전 기입 필수]';

  /// 법인/상호명
  static const String companyName = String.fromEnvironment(
    'COMPANY_NAME',
    defaultValue: '(주) 암행어흥',
  );

  /// 대표자 실명
  static const String ceoName = String.fromEnvironment(
    'COMPANY_CEO_NAME',
    defaultValue: _placeholder,
  );

  /// 사업자등록번호
  static const String businessRegistrationNumber = String.fromEnvironment(
    'COMPANY_BRN',
    defaultValue: _placeholder,
  );

  /// 통신판매업 신고번호
  static const String mailOrderSalesNumber = String.fromEnvironment(
    'COMPANY_MAIL_ORDER_NO',
    defaultValue: _placeholder,
  );

  /// 사업장 주소
  static const String address = String.fromEnvironment(
    'COMPANY_ADDRESS',
    defaultValue: _placeholder,
  );

  /// 고객센터 전화번호
  static const String customerServicePhone = String.fromEnvironment(
    'COMPANY_CS_PHONE',
    defaultValue: _placeholder,
  );

  /// 고객센터/개인정보 문의 이메일
  static const String privacyEmail = String.fromEnvironment(
    'COMPANY_PRIVACY_EMAIL',
    defaultValue: 'privacy@amhangeoheung.com',
  );

  /// 앱 버전 (pubspec.yaml 과 일치 유지)
  static const String appVersion = '1.0.0';

  /// 스토어 ID
  static const String iosAppId = String.fromEnvironment(
    'IOS_APP_ID',
    defaultValue: 'idXXXXXXXXXX',
  );
  static const String androidPackageId = String.fromEnvironment(
    'ANDROID_PACKAGE_ID',
    defaultValue: 'com.amhangeoheung.amhangeoheung_app',
  );

  /// 필수 법적 정보가 아직 placeholder 인지(=출시 준비 미완료) 여부.
  static bool get hasUnfilledLegalInfo =>
      ceoName == _placeholder ||
      businessRegistrationNumber == _placeholder ||
      address == _placeholder ||
      customerServicePhone == _placeholder;

  /// 스토어 ID 가 아직 placeholder 인지 여부.
  static bool get hasUnfilledStoreId => iosAppId == 'idXXXXXXXXXX';

  /// 운영 빌드에서 필수 법적 정보가 비어 있으면 예외를 던진다.
  /// main() 부팅 시 호출하여 미완성 상태의 운영 출시를 차단한다.
  static void assertReleaseReady() {
    if (!EnvironmentConfig.isProduction) return;
    if (!hasUnfilledLegalInfo) return;

    final missing = <String>[
      if (ceoName == _placeholder) 'COMPANY_CEO_NAME(대표자명)',
      if (businessRegistrationNumber == _placeholder) 'COMPANY_BRN(사업자등록번호)',
      if (address == _placeholder) 'COMPANY_ADDRESS(사업장 주소)',
      if (customerServicePhone == _placeholder) 'COMPANY_CS_PHONE(고객센터 전화)',
    ];
    throw StateError(
      '운영 빌드에 필수 사업자 법적 정보가 주입되지 않았습니다: '
      '${missing.join(', ')}. --dart-define 으로 주입 후 다시 빌드하세요.',
    );
  }

  /// 개발/스테이징에서 placeholder 가 남아 있으면 콘솔 경고를 남긴다(비차단).
  static void warnIfUnfilled() {
    if (hasUnfilledLegalInfo) {
      debugPrint(
        '[CompanyInfo] ⚠️ 사업자 법적 정보가 placeholder 상태입니다. '
        '출시 전 --dart-define 으로 실제 값을 주입하세요.',
      );
    }
  }
}
