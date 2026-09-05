-- ============================================
-- 011: 알림 수신 설정
-- --------------------------------------------
-- 앱의 "알림 설정" 화면은 스위치 6개를 보여주고 있었지만 저장되는 곳이
-- 없었다. 화면을 나가면 값이 사라지고 실제 발송에도 영향이 없었다.
--
-- 게다가 `PUT /users/me/notifications` 는 notification_push/email/sms 를
-- UPDATE 하고 있었는데 **그 컬럼들이 스키마에 없다.** 호출하면 그대로
-- 실패한다. 아무도 호출한 적이 없어서 드러나지 않았을 뿐이다.
--
-- 채널(push/email/sms)이 아니라 **종류**로 모델링한다. 이 앱이 실제로
-- 보내는 것은 FCM 푸시뿐이고, 이메일은 인증 메일에만 쓴다. 없는 채널을
-- 스위치로 두면 또 거짓말이 된다.
-- ============================================

-- 마스터 스위치. 끄면 푸시를 아예 보내지 않는다.
ALTER TABLE users ADD COLUMN IF NOT EXISTS notification_push BOOLEAN DEFAULT TRUE;

-- 종류별 스위치.
ALTER TABLE users ADD COLUMN IF NOT EXISTS notify_mission BOOLEAN DEFAULT TRUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS notify_review BOOLEAN DEFAULT TRUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS notify_settlement BOOLEAN DEFAULT TRUE;

-- 마케팅은 기본값이 FALSE 다. 광고성 정보는 수신 동의를 받은 사람에게만
-- 보낼 수 있다 (정보통신망법 제50조).
ALTER TABLE users ADD COLUMN IF NOT EXISTS notify_marketing BOOLEAN DEFAULT FALSE;

-- 야간(21:00~08:00 KST) 푸시 허용 여부. 기본값 FALSE.
-- 야간에 광고성 정보를 보내려면 별도의 야간 수신 동의가 필요하다.
ALTER TABLE users ADD COLUMN IF NOT EXISTS notify_night BOOLEAN DEFAULT FALSE;

-- 마케팅 수신 동의 시점. 동의를 받았다는 사실만으로는 부족하고 언제
-- 받았는지 남겨야 분쟁 때 증빙이 된다.
ALTER TABLE users ADD COLUMN IF NOT EXISTS marketing_agreed_at TIMESTAMPTZ;
