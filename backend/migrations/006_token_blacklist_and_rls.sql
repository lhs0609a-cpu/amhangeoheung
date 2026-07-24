-- Migration 006: Token blacklist table and RLS policies
-- P1-5: Logout token invalidation
-- P1-6: RLS policies for core tables

-- =====================================================
-- Token Blacklist Table
-- =====================================================
CREATE TABLE IF NOT EXISTS token_blacklist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  token_hash VARCHAR(64) NOT NULL,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_token_blacklist_hash ON token_blacklist(token_hash);
CREATE INDEX IF NOT EXISTS idx_token_blacklist_expires ON token_blacklist(expires_at);

-- =====================================================
-- RLS Policies (defense-in-depth)
-- Since the backend uses service_role key which bypasses RLS,
-- these policies are a defense-in-depth measure for if the client ever connects directly.
-- =====================================================

-- businesses: owners can CRUD their own, anyone can read
DROP POLICY IF EXISTS "businesses_select_all" ON businesses;
CREATE POLICY "businesses_select_all" ON businesses FOR SELECT USING (true);

DROP POLICY IF EXISTS "businesses_insert_owner" ON businesses;
CREATE POLICY "businesses_insert_owner" ON businesses FOR INSERT WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "businesses_update_owner" ON businesses;
CREATE POLICY "businesses_update_owner" ON businesses FOR UPDATE USING (owner_id = auth.uid());

-- missions: public read for active, business owners manage their own
DROP POLICY IF EXISTS "missions_select_public" ON missions;
CREATE POLICY "missions_select_public" ON missions FOR SELECT USING (status IN ('active', 'published', 'completed'));

DROP POLICY IF EXISTS "missions_insert_business" ON missions;
CREATE POLICY "missions_insert_business" ON missions FOR INSERT WITH CHECK (business_id IN (SELECT id FROM businesses WHERE owner_id = auth.uid()));

DROP POLICY IF EXISTS "missions_update_business" ON missions;
CREATE POLICY "missions_update_business" ON missions FOR UPDATE USING (business_id IN (SELECT id FROM businesses WHERE owner_id = auth.uid()));

-- escrows: only related parties can view
DROP POLICY IF EXISTS "escrows_select_parties" ON escrows;
CREATE POLICY "escrows_select_parties" ON escrows FOR SELECT USING (
  reviewer_id = auth.uid() OR
  business_id IN (SELECT id FROM businesses WHERE owner_id = auth.uid())
);

-- notifications: users can only see their own
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_select_own" ON notifications;
CREATE POLICY "notifications_select_own" ON notifications FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "notifications_update_own" ON notifications;
CREATE POLICY "notifications_update_own" ON notifications FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "notifications_delete_own" ON notifications;
CREATE POLICY "notifications_delete_own" ON notifications FOR DELETE USING (user_id = auth.uid());

-- whistleblower_reports: reporters can see their own
ALTER TABLE whistleblower_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "whistleblower_select_own" ON whistleblower_reports;
CREATE POLICY "whistleblower_select_own" ON whistleblower_reports FOR SELECT USING (reporter_id = auth.uid());

DROP POLICY IF EXISTS "whistleblower_insert_any" ON whistleblower_reports;
CREATE POLICY "whistleblower_insert_any" ON whistleblower_reports FOR INSERT WITH CHECK (true);

-- reviewer_earnings: users can only see their own
ALTER TABLE reviewer_earnings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "earnings_select_own" ON reviewer_earnings;
CREATE POLICY "earnings_select_own" ON reviewer_earnings FOR SELECT USING (reviewer_id = auth.uid());

-- device_tokens: users manage their own
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "device_tokens_select_own" ON device_tokens;
CREATE POLICY "device_tokens_select_own" ON device_tokens FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "device_tokens_insert_own" ON device_tokens;
CREATE POLICY "device_tokens_insert_own" ON device_tokens FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "device_tokens_delete_own" ON device_tokens;
CREATE POLICY "device_tokens_delete_own" ON device_tokens FOR DELETE USING (user_id = auth.uid());

-- Cleanup: schedule job to delete expired blacklist entries
-- (Will be handled by schedulerService)
