-- ============================================
-- 012: notifications.read_at 추가 + 스키마 불일치 정리
-- --------------------------------------------
-- `notifications` 테이블 정의가 두 곳에서 서로 다르다.
--
--   supabase/schema.sql              → message TEXT,  read_at 없음
--   migrations/001_create_...sql     → body TEXT,     read_at 있음
--
-- 코드도 갈라져 있었다.
--
--   notificationService.createNotification  → message 로 INSERT (15개 파일이 사용)
--   schedulerService                        → message 로 SELECT
--   notificationController.createNotification → body 로 INSERT (아무도 호출 안 함)
--   notificationController.markAsRead       → read_at 을 UPDATE
--   Flutter NotificationModel               → body / read_at 을 읽음
--
-- 실제로 쓰이는 쪽이 message 이므로 schema.sql 을 정본으로 본다. 001 은
-- 적용된 적이 없는 초안으로 남겨두되, 그걸 믿고 짠 코드가 남아 있었다.
--
-- 그 결과 두 가지가 조용히 깨져 있었다.
--   1. markAsRead/markAllAsRead 가 없는 컬럼(read_at)을 UPDATE 해서 실패
--      → 알림을 읽음 처리할 수 없었다.
--   2. 앱이 없는 컬럼(body)을 읽어서 알림 본문이 항상 비어 있었다.
--
-- read_at 은 실제로 쓸모가 있으므로(언제 읽었는지) 지우지 않고 추가한다.
-- IF NOT EXISTS 라서 001 이 적용된 DB 에서도 안전하다.
-- ============================================

ALTER TABLE notifications ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ;

-- 이미 읽음 처리된 알림에는 읽은 시각을 알 수 없으므로 생성 시각으로 채운다.
-- NULL 로 두면 "읽었는데 읽은 시각이 없는" 행이 영구히 남는다.
UPDATE notifications
   SET read_at = created_at
 WHERE is_read = TRUE
   AND read_at IS NULL;
