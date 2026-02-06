# Flutter Web Build Script for Windows
# Usage: .\scripts\build_web.ps1 [environment]
# Environments: dev, staging, prod

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

# Clean previous build
Write-Host "`nCleaning previous build..." -ForegroundColor Gray
if (Test-Path "build/web") {
    Remove-Item -Recurse -Force "build/web"
}

# Run flutter build
Write-Host "`nRunning flutter build web..." -ForegroundColor Gray
flutter build web `
    --release `
    --web-renderer html `
    --dart-define=ENV=$ENV_VALUE `
    --dart-define=API_URL=$API_URL

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
