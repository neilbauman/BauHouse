-- Civic projects: one record per week
CREATE TABLE civic_projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  week_number INTEGER NOT NULL,
  year INTEGER NOT NULL,
  building_name TEXT NOT NULL,
  puzzle_data JSONB NOT NULL,
  solution_data JSONB NOT NULL,
  completion_count INTEGER DEFAULT 0,
  opens_at TIMESTAMPTZ NOT NULL,
  closes_at TIMESTAMPTZ NOT NULL,
  UNIQUE(week_number, year)
);

ALTER TABLE civic_projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Civic projects are publicly readable"
  ON civic_projects FOR SELECT
  USING (true);
