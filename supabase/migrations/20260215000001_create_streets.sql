-- Streets table: Fictional Elmfield streets. Pre-seeded.
CREATE TABLE streets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  district TEXT NOT NULL CHECK (district IN ('elmfield', 'gropius')),
  max_plots INTEGER DEFAULT 20,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE streets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Streets are publicly readable"
  ON streets FOR SELECT
  USING (true);
