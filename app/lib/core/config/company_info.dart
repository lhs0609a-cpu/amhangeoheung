/// 회사 법적 정보 (사업자 정보, 연락처 등)
///
/// ⚠️ 스토어 출시 전 아래 placeholder 값을 실제 값으로 반드시 교체해야 합니다.
/// 전자상거래법/위치정보법상 사업자등록번호·대표자명·주소·고객센터 표기는 필수입니다.
/// 모든 화면/약관이 이 상수를 참조하므로, 여기 한 곳만 고치면 됩니다.
class CompanyInfo {
  CompanyInfo._();

  /// 법인/상호명
  static const String companyName = '(주) 암행어흥';

  /// 대표자 실명 — TODO: 출시 전 실제 값으로 교체
  static const String ceoName = '[출시 전 기입 필수]';

  /// 사업자등록번호 — TODO: 출시 전 실제 값으로 교체
  static const String businessRegistrationNumber = '[출시 전 기입 필수]';

  /// 통신판매업 신고번호 — TODO: 해당 시 기입
  static const String mailOrderSalesNumber = '[출시 전 기입 필수]';

  /// 사업장 주소 — TODO: 출시 전 실제 값으로 교체
  static const String address = '[출시 전 기입 필수]';

  /// 고객센터 전화번호 — TODO: 출시 전 실제 값으로 교체
  static const String customerServicePhone = '[출시 전 기입 필수]';

  /// 고객센터/개인정보 문의 이메일
  static const String privacyEmail = 'privacy@amhangeoheung.com';

  /// 앱 버전 (pubspec.yaml 과 일치 유지)
  static const String appVersion = '1.0.0';

  /// 스토어 ID — TODO: 출시 후 실제 ID로 교체
  static const String iosAppId = 'idXXXXXXXXXX';
  static const String androidPackageId = 'com.amhangeoheung.amhangeoheung_app';

  /// placeholder가 아직 남아있는지(=출시 준비 미완료) 여부.
  /// 디버그 빌드에서 경고를 띄우는 등에 사용할 수 있다.
  static bool get hasUnfilledLegalInfo =>
      ceoName.contains('출시 전') ||
      businessRegistrationNumber.contains('출시 전') ||
      address.contains('출시 전') ||
      customerServicePhone.contains('출시 전');
}
