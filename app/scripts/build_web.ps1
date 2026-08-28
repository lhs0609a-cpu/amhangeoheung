# Flutter Web Build Script for Windows
# Usage: .\scripts\build_web.ps1 [environment]
# Environments: dev, staging, prod
#
# 운영 빌드에 필요한 값은 환경 변수로 주입한다(레포에 커밋하지 않기 위해).
#   $env:COMPANY_CEO_NAME    = "대표자명"
#   $env:COMPANY_BRN         = "123-45-67890"
#   $env:COMPANY_ADDRESS     = "서울특별시 ..."
#   $env:COMPANY_CS_PHONE    = "1600-0000"
#   $env:TOSS_CLIENT_KEY     = "live_ck_..."
# 선택: COMPANY_NAME, COMPANY_MAIL_ORDER_NO, COMPANY_PRIVACY_EMAIL,
#       IOS_APP_ID, ANDROID_PACKAGE_ID, KAKAO_NATIVE_APP_KEY, API_URL

param(
    [Parameter(Position=0)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment = "prod"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Flutter Web Build Script" -ForegroundColor Cyan
Write-Host "  Environment: $Environment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Set environment variables based on environment
switch ($Environment) {
    "dev" {
        $ENV_VALUE = "development"
        $API_URL = "http://localhost:3000/api"
        Write-Host "`n[DEV] Building for development..." -ForegroundColor Yellow
    }
    "staging" {
        $ENV_VALUE = "staging"
        $API_URL = "https://amhangeoheung-backend-staging.fly.dev/api"
        Write-Host "`n[STAGING] Building for staging..." -ForegroundColor Yellow
    }
    "prod" {
        $ENV_VALUE = "production"
        $API_URL = "https://amhangeoheung-backend.fly.dev/api"
        Write-Host "`n[PROD] Building for production..." -ForegroundColor Green
    }
}

# API_URL 은 환경 변수로 덮어쓸 수 있다.
if ($env:API_URL) { $API_URL = $env:API_URL }

# ── 운영 빌드 사전 검증 ────────────────────────────────────────────────────
# main() 의 CompanyInfo.assertReleaseReady() 가 아래 4개 중 하나라도 비어 있으면
# 부팅 시점에 StateError 를 던져 앱이 흰 화면으로 죽는다. 20분짜리 빌드를 돌리기
# 전에 여기서 먼저 막는다. TOSS_CLIENT_KEY 는 운영 기본값이 빈 문자열이라
# 누락되면 결제만 조용히 실패하므로 함께 검사한다.
$requiredForProd = @(
    @{ Key = "COMPANY_CEO_NAME"; Label = "대표자명" },
    @{ Key = "COMPANY_BRN";      Label = "사업자등록번호" },
    @{ Key = "COMPANY_ADDRESS";  Label = "사업장 주소" },
    @{ Key = "COMPANY_CS_PHONE"; Label = "고객센터 전화" },
    @{ Key = "TOSS_CLIENT_KEY";  Label = "Toss 운영 클라이언트 키" }
)

if ($Environment -eq "prod") {
    $missing = @()
    foreach ($item in $requiredForProd) {
        if (-not [Environment]::GetEnvironmentVariable($item.Key)) {
            $missing += "  - `$env:$($item.Key)  ($($item.Label))"
        }
    }
    if ($missing.Count -gt 0) {
        Write-Host "`n운영 빌드에 필요한 값이 주입되지 않았습니다:" -ForegroundColor Red
        $missing | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        Write-Host "`n전자상거래법상 필수 표기 항목입니다. 값을 설정한 뒤 다시 실행하세요." -ForegroundColor Yellow
        exit 1
    }
}

# ── dart-define 조립 ───────────────────────────────────────────────────────
$defines = @(
    "--dart-define=ENV=$ENV_VALUE",
    "--dart-define=API_URL=$API_URL"
)

# 설정된 것만 전달한다. 미설정 항목은 앱의 기본값(placeholder)이 쓰인다.
$optionalKeys = @(
    "COMPANY_NAME", "COMPANY_CEO_NAME", "COMPANY_BRN", "COMPANY_MAIL_ORDER_NO",
    "COMPANY_ADDRESS", "COMPANY_CS_PHONE", "COMPANY_PRIVACY_EMAIL",
    "IOS_APP_ID", "ANDROID_PACKAGE_ID",
    "TOSS_CLIENT_KEY", "KAKAO_NATIVE_APP_KEY"
)
foreach ($key in $optionalKeys) {
    $value = [Environment]::GetEnvironmentVariable($key)
    if ($value) { $defines += "--dart-define=$key=$value" }
}

# Clean previous build
Write-Host "`nCleaning previous build..." -ForegroundColor Gray
if (Test-Path "build/web") {
    Remove-Item -Recurse -Force "build/web"
}

# Run flutter build
# NOTE: --web-renderer 는 쓰지 않는다. Flutter 는 HTML 렌더러를 제거했고
#       (bin/cache/flutter_web_sdk 에 canvaskit / skwasm 만 존재한다)
#       렌더러는 기본값(canvaskit)으로 결정된다. WASM 빌드가 필요하면 --wasm 을 쓴다.
Write-Host "`nRunning flutter build web..." -ForegroundColor Gray
Write-Host "  defines: $($defines.Count)개" -ForegroundColor DarkGray
flutter build web --release @defines

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nBuild failed!" -ForegroundColor Red
    exit 1
}

# Calculate build size
$buildSize = (Get-ChildItem -Recurse "build/web" | Measure-Object -Property Length -Sum).Sum / 1MB
$buildSizeFormatted = "{0:N2}" -f $buildSize

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  Build completed successfully!" -ForegroundColor Green
Write-Host "  Output: build/web/" -ForegroundColor Green
Write-Host "  Size: $buildSizeFormatted MB" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Test locally: flutter run -d chrome" -ForegroundColor White
Write-Host "  2. Deploy to Vercel: vercel --prod" -ForegroundColor White
Write-Host "  3. Or deploy to Firebase: firebase deploy" -ForegroundColor White
