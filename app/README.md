# 암행어흥

독립 감찰 기록으로 업체의 장단점과 개선 과정을 확인하는 리뷰 신뢰 플랫폼입니다.

- [제품 설계 명세](../docs/PRODUCT_SPEC.md)
- [조사·디자인 보고서](../docs/quality-report.html)
- [기존 디자인 시스템](DESIGN_SYSTEM.md)
- [배포 가이드](DEPLOY.md)
- [검증 기록](../docs/qa/VALIDATION.md)

Flutter 앱은 이 디렉터리, Express/Supabase API는 ../backend에 있습니다.

```powershell
flutter pub get
flutter analyze
flutter test
```

운영 API·결제·회사 정보는 DEPLOY.md의 환경별 설정을 따릅니다. 디자인 시안과 테스트 데이터는 운영 업체 데이터가 아닙니다.
