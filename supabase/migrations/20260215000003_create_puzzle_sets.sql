-- Puzzle sets: one record per calendar day
CREATE TABLE puzzle_sets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scheduled_date DATE NOT NULL UNIQUE,
  project_name TEXT NOT NULL,
  client_name TEXT NOT NULL,
  brief_intro TEXT NOT NULL,
  completion_text TEXT NOT NULL,
  week_number INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE puzzle_sets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Puzzle sets are publicly readable"
  ON puzzle_sets FOR SELECT
  USING (true);
