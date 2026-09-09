# 저장소 문서·화면·데이터 설계 목록

기준일 2026-09-09. 문서와 라우트/화면 파일 목록을 확인했다. 모든 소스 줄에 대한 감사 완료를 뜻하지 않는다.

## 확인한 기존 문서

- app/DESIGN_SYSTEM.md: 제품 원칙·토큰·컴포넌트·미완료 사항. 전문 확인.
- app/DEPLOY.md: 환경별 빌드·회사정보·결제 키·배포 방식. 전문 확인.
- app/README.md: 기존 Flutter 템플릿. 이번에 제품 문서 진입점으로 교체.
- 별도 PDF/HWP/DOCX/PPTX/XLSX 기획서는 저장소에서 발견되지 않음.

## 코드에 포함된 정책 근거

- backend/src/config/constants.js: 역할·보상·기간·등급·유형·구독
- app/lib/features/legal/data/legal_content.dart: 약관·개인정보·위치 정책(관련 조항 검토)
- app/pubspec.yaml / backend/package.json: 구현 스택과 검증 명령
- backend/src/routes / app/lib/app_router.dart: 역할별 접근·화면/API 계약

## 화면 파일 49개

- `app/lib/features/accessibility/presentation/screens/accessibility_screen.dart`
- `app/lib/features/auth/presentation/screens/email_verification_screen.dart`
- `app/lib/features/auth/presentation/screens/forgot_password_screen.dart`
- `app/lib/features/auth/presentation/screens/login_screen.dart`
- `app/lib/features/auth/presentation/screens/onboarding_screen.dart`
- `app/lib/features/auth/presentation/screens/register_screen.dart`
- `app/lib/features/auth/presentation/screens/splash_screen.dart`
- `app/lib/features/business/presentation/screens/business_onboarding_screen.dart`
- `app/lib/features/business/presentation/screens/cancel_subscription_screen.dart`
- `app/lib/features/business/presentation/screens/preview_reviews_screen.dart`
- `app/lib/features/certification/presentation/screens/certification_home_screen.dart`
- `app/lib/features/certification/presentation/screens/final_exam_screen.dart`
- `app/lib/features/certification/presentation/screens/training_module_screen.dart`
- `app/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `app/lib/features/detection_test/presentation/screens/detection_test_screen.dart`
- `app/lib/features/detection_test/presentation/screens/stealth_stats_screen.dart`
- `app/lib/features/home/presentation/screens/home_screen.dart`
- `app/lib/features/legal/presentation/screens/legal_screen.dart`
- `app/lib/features/mission/presentation/screens/create_mission_screen.dart`
- `app/lib/features/mission/presentation/screens/mission_detail_screen.dart`
- `app/lib/features/mission/presentation/screens/mission_list_screen.dart`
- `app/lib/features/mission/presentation/screens/season_detail_screen.dart`
- `app/lib/features/mission/presentation/screens/tutorial_mission_screen.dart`
- `app/lib/features/notification/presentation/screens/notification_screen.dart`
- `app/lib/features/onboarding/presentation/screens/free_trial_screen.dart`
- `app/lib/features/onboarding/presentation/screens/user_type_selection_screen.dart`
- `app/lib/features/payment/presentation/screens/toss_payment_screen.dart`
- `app/lib/features/portfolio/presentation/screens/portfolio_screen.dart`
- `app/lib/features/pricing/presentation/screens/business_pricing_screen.dart`
- `app/lib/features/pricing/presentation/screens/pricing_screen.dart`
- `app/lib/features/profile/presentation/screens/about_screen.dart`
- `app/lib/features/profile/presentation/screens/bank_account_screen.dart`
- `app/lib/features/profile/presentation/screens/edit_profile_screen.dart`
- `app/lib/features/profile/presentation/screens/my_reviews_screen.dart`
- `app/lib/features/profile/presentation/screens/notifications_settings_screen.dart`
- `app/lib/features/profile/presentation/screens/profile_screen.dart`
- `app/lib/features/profile/presentation/screens/settlements_screen.dart`
- `app/lib/features/profile/presentation/screens/specialties_screen.dart`
- `app/lib/features/profile/presentation/screens/support_screen.dart`
- `app/lib/features/ranking/presentation/screens/ranking_screen.dart`
- `app/lib/features/ranking/presentation/screens/regional_ranking_screen.dart`
- `app/lib/features/referral/presentation/screens/invite_screen.dart`
- `app/lib/features/review/presentation/screens/review_detail_screen.dart`
- `app/lib/features/review/presentation/screens/review_list_screen.dart`
- `app/lib/features/review/presentation/screens/write_review_screen.dart`
- `app/lib/features/review_request/presentation/screens/request_review_screen.dart`
- `app/lib/features/search/presentation/screens/search_screen.dart`
- `app/lib/features/settings/presentation/screens/settings_screen.dart`
- `app/lib/features/trust/presentation/screens/trust_analysis_screen.dart`

## 라우트 53개

- `/splash`
- `/onboarding`
- `/login`
- `/register`
- `/forgot-password`
- `/verify-email`
- `/select-user-type`
- `/try-free`
- `/tutorial-mission`
- `/home`
- `/missions`
- `/ranking`
- `/reviews`
- `/profile`
- `/dashboard`
- `/search`
- `/my-activity`
- `/trust-overview`
- `/missions/create`
- `/missions/:id`
- `/reviews/:id`
- `/write-review/:missionId`
- `/trust/:businessId`
- `/pricing`
- `/business-onboarding`
- `/business-pricing`
- `/notifications`
- `/preview-reviews`
- `/settings`
- `/portfolio/:userId`
- `/accessibility`
- `/terms`
- `/privacy`
- `/location-privacy`
- `/marketing`
- `/seasons/:id`
- `/invite`
- `/business/:id/cancel`
- `/ranking/regional`
- `/request-review/:businessId`
- `/certification`
- `/certification/training/:day`
- `/certification/exam`
- `/detection-test/:id`
- `/stealth-stats`
- `/edit-profile`
- `/my-reviews`
- `/settlements`
- `/specialties`
- `/bank-account`
- `/support`
- `/notifications-settings`
- `/about`

## 스키마·마이그레이션 파일

- `backend/migrations/001_create_notifications_table.sql`
- `backend/migrations/004_motivation_quality_alternatives.sql`
- `backend/migrations/005_atomic_increments_and_fixes.sql`
- `backend/migrations/006_token_blacklist_and_rls.sql`
- `backend/migrations/007_business_subscription_columns.sql`
- `backend/migrations/008_receipt_review_status.sql`
- `backend/migrations/009_business_monthly_revenue.sql`
- `backend/migrations/010_review_findings.sql`
- `backend/migrations/011_notification_preferences.sql`
- `backend/migrations/012_notifications_read_at.sql`
- `backend/supabase/migrations/20240101_add_social_login.sql`
- `backend/supabase/schema.sql`
- `backend/supabase/seed_training_modules.sql`
