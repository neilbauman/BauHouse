-- Puzzles: 10 per puzzle_set (5 schematic + 5 design)
CREATE TABLE puzzles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  puzzle_set_id UUID NOT NULL REFERENCES puzzle_sets(id),
  puzzle_type TEXT NOT NULL CHECK (puzzle_type IN ('parcel', 'setback', 'draft', 'conduit', 'lamp')),
  mode TEXT NOT NULL CHECK (mode IN ('schematic', 'design')),
  slot_number INTEGER NOT NULL CHECK (slot_number BETWEEN 1 AND 5),
  difficulty_score NUMERIC(4,2) NOT NULL,
  grid_data JSONB NOT NULL,
  solution_data JSONB NOT NULL,
  task_description TEXT NOT NULL,
  avg_solve_seconds INTEGER,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE puzzles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Puzzles are readable without solution"
  ON puzzles FOR SELECT
  USING (true);

-- Secure view that excludes solution_data — clients query this instead
CREATE VIEW puzzles_client AS
  SELECT id, puzzle_set_id, puzzle_type, mode, slot_number,
         difficulty_score, grid_data, task_description, avg_solve_seconds, created_at
  FROM puzzles;
