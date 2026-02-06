# 암행어흥 - Flutter Web 배포 가이드

## 빌드 명령어

### 1. 프로덕션 빌드 (권장)
```powershell
# Windows PowerShell
.\scripts\build_web.ps1 prod

# 또는 직접 명령어
flutter build web --release --web-renderer html --dart-define=ENV=production
```

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
```bash
# HTML 렌더러 (권장 - 초기 로딩 빠름, 호환성 좋음)
flutter build web --web-renderer html

# CanvasKit 렌더러 (그래픽 성능 좋음, 로딩 느림)
flutter build web --web-renderer canvaskit
```

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
