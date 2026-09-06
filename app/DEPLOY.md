# 암행어흥 - Flutter Web 배포 가이드

## 빌드 명령어

### 1. 프로덕션 빌드 (권장)

운영 빌드에 필요한 값은 **환경 변수로 주입**한다. `build_web.ps1` 이 이 값들을
`--dart-define` 으로 옮겨주고, 하나라도 비어 있으면 빌드를 시작하기 전에 중단한다.

```powershell
$env:COMPANY_CEO_NAME = "대표자명"
$env:COMPANY_BRN      = "123-45-67890"
$env:COMPANY_ADDRESS  = "서울특별시 ..."
$env:COMPANY_CS_PHONE = "1600-0000"
$env:TOSS_CLIENT_KEY  = "live_ck_xxx"

.\scripts\build_web.ps1 prod
```

선택 항목: `COMPANY_NAME`, `COMPANY_MAIL_ORDER_NO`, `COMPANY_PRIVACY_EMAIL`,
`IOS_APP_ID`, `ANDROID_PACKAGE_ID`, `KAKAO_NATIVE_APP_KEY`, `API_URL`
(설정하면 전달되고, 안 하면 앱의 기본값이 쓰인다)

> ⚠️ **왜 스크립트가 미리 막는가**
> `main()` 이 부팅 직후 `CompanyInfo.assertReleaseReady()` 를 호출한다. 위 4개
> 회사 정보 중 하나라도 placeholder 면 `StateError` 를 던져 **앱이 흰 화면으로
> 죽는다**(전자상거래법 필수 표기 누락 방지). `TOSS_CLIENT_KEY` 는 운영 기본값이
> 빈 문자열이라 누락돼도 부팅은 되지만 **결제만 조용히 실패**한다.
> 빌드에 수십 분이 걸리므로 스크립트가 시작 전에 먼저 검사한다.
>
> 직접 명령어로 빌드한다면 이 검사가 없으니 누락에 주의할 것:
> ```
> flutter build web --release \
>   --dart-define=ENV=production \
>   --dart-define=COMPANY_CEO_NAME=대표자명 \
>   --dart-define=COMPANY_BRN=123-45-67890 \
>   --dart-define=COMPANY_MAIL_ORDER_NO=2026-지역-00000 \
>   --dart-define=COMPANY_ADDRESS="사업장 주소" \
>   --dart-define=COMPANY_CS_PHONE=1600-0000 \
>   --dart-define=TOSS_CLIENT_KEY=live_ck_xxx \
>   --dart-define=IOS_APP_ID=id1234567890
> ```

### 2. 스테이징 빌드
```powershell
.\scripts\build_web.ps1 staging
```

### 3. 개발 빌드
```powershell
.\scripts\build_web.ps1 dev
```

---

## 배포 옵션

### Option A: Vercel (권장 - 무료, 빠름)

1. **Vercel CLI 설치**
```bash
npm i -g vercel
```

2. **로그인**
```bash
vercel login
```

3. **배포**
```bash
# 프리뷰 배포
vercel

# 프로덕션 배포
vercel --prod
```

4. **환경변수 설정 (Vercel Dashboard)**
- `API_URL`: https://amhangeoheung-backend.fly.dev/api

### Option B: Firebase Hosting

1. **Firebase CLI 설치**
```bash
npm i -g firebase-tools
```

2. **로그인 & 프로젝트 설정**
```bash
firebase login
firebase init hosting
```

3. **배포**
```bash
firebase deploy --only hosting
```

### Option C: Netlify

1. **빌드 후 build/web 폴더를 Netlify에 드래그 앤 드롭**

2. **또는 netlify.toml 생성**
```toml
[build]
  publish = "build/web"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

---

## 로컬 테스트

```bash
# 크롬에서 실행
flutter run -d chrome

# 또는 빌드 후 로컬 서버로 테스트
cd build/web
python -m http.server 8000
# http://localhost:8000 접속
```

---

## 환경별 API URL

| 환경 | API URL |
|------|---------|
| Development | http://localhost:3000/api |
| Staging | https://amhangeoheung-backend-staging.fly.dev/api |
| Production | https://amhangeoheung-backend.fly.dev/api |

---

## 성능 최적화 팁

### 1. 빌드 렌더러 선택
`--web-renderer` 플래그와 HTML 렌더러는 제거되었다. 현재 SDK 가 내려주는 웹 렌더러는
`bin/cache/flutter_web_sdk/canvaskit/` 에 있는 **CanvasKit** 과 **skwasm** 둘뿐이다.

```bash
# 기본 (CanvasKit)
flutter build web --release

# WebAssembly 빌드 (skwasm) — 더 빠르지만 브라우저 요구사항이 높다
flutter build web --release --wasm
```

> 초기 로딩 용량이 문제라면 렌더러를 바꾸는 대신 지연 로딩(deferred import)과
> 폰트 서브셋을 검토한다. HTML 렌더러로 되돌아갈 선택지는 더 이상 없다.

### 2. 트리 쉐이킹 (자동)
- `--release` 플래그 사용 시 자동으로 사용하지 않는 코드 제거

### 3. gzip 압축
- Vercel/Firebase는 자동으로 gzip 압축 적용

---

## 트러블슈팅

### CORS 에러
백엔드에서 프론트엔드 도메인 허용 필요:
```javascript
// backend/src/server.js
app.use(cors({
  origin: [
    'http://localhost:8000',
    'https://amhangeoheung.vercel.app',
    'https://amhangeoheung.com'
  ]
}));
```

### 새로고침 시 404 에러
- SPA이므로 모든 경로를 index.html로 리다이렉트 필요
- vercel.json, firebase.json에 이미 설정됨

### iOS Safari에서 PWA 설치 안 됨
- HTTPS 필수
- manifest.json의 icons 확인
