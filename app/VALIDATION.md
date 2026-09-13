# 검증 기록

검증 환경: Windows / Flutter 3.47.2 / Dart 3.13.2 / Node 24.18.0.

## 통과한 확인

- 최종 Flutter 전체 테스트 19개 통과 (`flutter test --no-pub`).
- 사용자 모델 회귀 테스트 2개 통과: DB의 snake_case 응답과 로그인 camelCase 응답, 역할·등급·계좌·구독·직렬화 보존.
- 서버 위치 계산·설정 상수 테스트 13개 통과 (`node --test test/geoUtils.test.js test/constants.test.js`). 전체 서버 테스트 실행 결과는 아니다.
- 이미지 URL 배열/업로드 객체/빈 데이터 파싱, 320px 폭·150% 글자 크기 배너, 신뢰도 리뷰 없음·조회 실패 화면 테스트 포함.
- 디자인 HTML의 JavaScript 구문 검사 통과.
- `git diff --check` 통과.

## 검증 범위와 제약

- `flutter pub get`은 의존성 다운로드와 lockfile 갱신 후 Windows 개발자 모드의 심볼릭 링크 제한으로 종료 코드 1을 반환했다. 이후 `--no-pub` 분석·테스트를 사용했다. 시스템 설정을 임의 변경하지 않았다.
- 브랜드 개편 이후 전체 분석: 컴파일 오류 0개, 경고 36개, 정보 358개. Flutter 전체 테스트 19개 통과.
- 새 HTML 시안을 Chrome headless에서 렌더링·캡처해 생성 이미지와 첫 화면 배치를 확인했다. 데스크톱 결과: `brand-preview-desktop.png`.
- Android/iOS 실기기, 전체 웹 빌드, 실제 API·DB의 종단 간 흐름은 검증하지 않았다.
- 실제 계정 로그인·결제 승인·정산·푸시·영수증 검증의 성공을 주장하지 않는다. 필요한 외부 설정과 화면별 합격 조건은 `DESIGN_PLAN.ko.md`에 정리했다.
- 기존 미사용 코드·deprecated API 등의 경고/정보는 전체 정리 범위에 포함하지 않았다.

## 암행어흥 브랜드 개편

- 기본 이미지 생성 도구로 캐릭터·출두·선발 시험·청탁 거절·마패 총 5종을 생성했다.
- 원본 이미지를 육안 확인하고 앱 자산 폴더에 복사했다. 홈·시작·온보딩·선발원·어사 원칙 화면에 연결했다.
- 새 브랜드 선언문이 320px·150% 글자 크기 조건에서 렌더링되는 회귀 테스트를 통과했다.
- 선발 시험과 파면 절차는 UI/운영 설계를 반영했다. 실제 파면 처리 시스템을 추가 구현하거나 운영에서 실행한 것은 아니다.

## 재현 명령

```powershell
cd app
flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings
flutter test --no-pub
```

`--no-fatal-*`는 경고/정보로 종료 코드를 실패 처리하지 않게 하며, 컴파일 오류는 계속 실패 처리한다.
