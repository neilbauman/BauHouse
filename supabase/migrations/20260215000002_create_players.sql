-- Players table: one record per device/account
CREATE TABLE players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  house_style TEXT NOT NULL CHECK (house_style IN ('classic', 'modern', 'cottage')),
  accent_colour TEXT NOT NULL,
  street_id UUID REFERENCES streets(id),
  plot_number INTEGER NOT NULL,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  builder_credits INTEGER DEFAULT 0,
  is_premium BOOLEAN DEFAULT false,
  last_active_date DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE players ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Players can read own row"
  ON players FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Players can update own row"
  ON players FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Service role can insert players"
  ON players FOR INSERT
  WITH CHECK (auth.uid() = id);
