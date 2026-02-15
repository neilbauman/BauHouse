-- Credit transactions: immutable ledger of all Builder's Credit events
CREATE TABLE credit_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  player_id UUID NOT NULL REFERENCES players(id),
  amount INTEGER NOT NULL,
  reason TEXT NOT NULL CHECK (reason IN (
    'daily_complete', 'morning_complete', 'streak_7',
    'civic_complete', 'rewarded_ad', 'unlock_archive',
    'hint', 'streak_shield'
  )),
  reference_id UUID,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Players can read own transactions"
  ON credit_transactions FOR SELECT
  USING (auth.uid() = player_id);

CREATE POLICY "Players can insert own transactions"
  ON credit_transactions FOR INSERT
  WITH CHECK (auth.uid() = player_id);
